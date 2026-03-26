# 🚀 GMAO — Pipeline CI/CD complet (Terraform + GitHub Actions)

## Architecture du pipeline

```
git push main
     │
     ▼
┌─────────────────────────────────────────────────────┐
│  JOB 1 — Création VM EC2                            │
│  ├─ Terraform init / plan / apply                   │
│  ├─ Ubuntu 20.04 LTS | t2.large | key: vockey       │
│  ├─ Security Group : ports 22, 8080, 3000           │
│  └─ Export IP publique → jobs suivants              │
└────────────────────┬────────────────────────────────┘
                     │  needs: job1
                     ▼
┌─────────────────────────────────────────────────────┐
│  JOB 2 — Post-Installation (via SSH)                │
│  ├─ apt update + upgrade                            │
│  ├─ Java 11 (requis par Spring Boot)                │
│  ├─ Maven                                           │
│  ├─ PostgreSQL + démarrage service                  │
│  ├─ Node.js 18 LTS + npm                            │
│  ├─ wget gmao-backend.tar.gz + frontend             │
│  └─ tar xzf (décompression)                        │
└────────────────────┬────────────────────────────────┘
                     │  needs: job1, job2
                     ▼
┌─────────────────────────────────────────────────────┐
│  JOB 3 — Démarrage Application (via SSH)            │
│  ├─ restore.sh gmao_backup_20260324_1458.sql        │
│  ├─ mvn spring-boot:run  (port 8080, background)    │
│  └─ npm start --disable-host-check (port 3000)     │
└─────────────────────────────────────────────────────┘
```

---

## Structure des fichiers

```
gmao-pipeline/
├── .github/
│   └── workflows/
│       └── deploy.yml          ← Pipeline GitHub Actions (3 jobs)
├── terraform/
│   ├── main.tf                 ← EC2 + Security Group AWS
│   ├── variables.tf            ← Région, type instance, key_name
│   └── outputs.tf              ← IP publique, instance_id
├── scripts/
│   ├── 02_post_install.sh      ← Java, Maven, PostgreSQL, Node, projets
│   └── 03_start_app.sh         ← Restore DB + Spring Boot + React
└── README.md
```

---

## ⚙️ Étapes de configuration

### 1. Créer le dépôt GitHub

```bash
git init
git add .
git commit -m "initial commit"
git remote add origin https://github.com/TON_USER/gmao-pipeline.git
git push -u origin main
```

### 2. Ajouter les GitHub Secrets

Va dans ton repo → **Settings → Secrets and variables → Actions → New repository secret**

| Nom du secret           | Valeur                                      |
|-------------------------|---------------------------------------------|
| `AWS_ACCESS_KEY_ID`     | Depuis AWS Academy → Credentials            |
| `AWS_SECRET_ACCESS_KEY` | Depuis AWS Academy → Credentials            |
| `AWS_SESSION_TOKEN`     | Depuis AWS Academy → Credentials            |
| `SSH_PRIVATE_KEY`       | Contenu complet du fichier `labsuser.pem`   |

> ⚠️ Le `SSH_PRIVATE_KEY` doit inclure les lignes `-----BEGIN RSA PRIVATE KEY-----` et `-----END RSA PRIVATE KEY-----`

### 3. Récupérer la clé vockey (labsuser.pem)

Dans **AWS Academy** :
1. Ouvre ton Lab
2. Clique sur **AWS Details**
3. Clique sur **Download PEM**
4. Copie le contenu entier dans le secret `SSH_PRIVATE_KEY`

### 4. Lancer le pipeline

```bash
git push origin main
# OU depuis GitHub → Actions → "GMAO — Deploy Pipeline" → Run workflow
```

---

## 📋 Ce qui a été ajouté par rapport à ta demande initiale

| Étape ajoutée | Raison |
|---|---|
| **Java 11** | Spring Boot en a absolument besoin |
| **Node.js 18 via NodeSource** | `apt install npm` installe une version obsolète (Node 10) incompatible React |
| **Security Group AWS** | Sans ça, les ports 8080 et 3000 sont bloqués |
| **Attente SSH** | La VM met ~60s à démarrer avant d'accepter les connexions |
| **Création rôle PostgreSQL** | AWS Ubuntu n'a pas de rôle `ubuntu` par défaut |
| **`npm install`** | Nécessaire avant `npm start` si `node_modules` est absent |
| **`fuser -k`** | Évite les conflits si les ports 8080/3000 sont déjà utilisés |
| **Tests de connectivité** | Vérifie que les apps répondent vraiment après démarrage |
| **`BROWSER=none`** | Empêche React de tenter d'ouvrir un navigateur sur le serveur |

---

## 🔧 Commandes utiles sur la VM

```bash
# Connexion SSH
ssh -i ~/.ssh/labsuser.pem ubuntu@<PUBLIC_IP>

# Logs en temps réel
tail -f /tmp/gmao-backend.log
tail -f /tmp/gmao-frontend.log
tail -f /tmp/post_install.log

# Arrêter les applications
kill $(cat /tmp/gmao-backend.pid)
kill $(cat /tmp/gmao-frontend.pid)

# Statut PostgreSQL
sudo systemctl status postgresql
```

---

## ⚠️ Notes importantes

- Les credentials **AWS Academy expirent toutes les 4h** → mets à jour les secrets GitHub à chaque session
- Le pipeline complet dure environ **10-15 minutes** (Maven télécharge beaucoup de dépendances)
- Si `terraform apply` échoue avec "key pair not found", vérifie que `vockey` existe bien dans ta région AWS
