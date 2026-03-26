#!/bin/bash
# =============================================================================
# JOB 2 — Post-installation GMAO
# Packages : Java 17, Maven, PostgreSQL, Node.js/npm
# Projets  : gmao-backend (Spring Boot) + gmao-frontend (Angular)
# =============================================================================
set -euo pipefail
LOG="/tmp/post_install.log"
exec > >(tee -a "$LOG") 2>&1

echo "============================================"
echo "  JOB 2 — POST-INSTALLATION  $(date)"
echo "============================================"

# ── [1/8] Mise à jour du système ─────────────────────────────────────────────
echo ""
echo "[1/8] Mise à jour des paquets système..."
export DEBIAN_FRONTEND=noninteractive
sudo apt update -y
sudo apt upgrade -y
sudo apt install -y curl wget gnupg2 software-properties-common apt-transport-https ca-certificates unzip

# ── [2/8] Java 17 (requis par Spring Boot 3.x / Maven) ───────────────────────
echo ""
echo "[2/8] Installation de Java 17..."
sudo apt install -y openjdk-17-jdk
java -version
echo "JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))" | sudo tee -a /etc/environment
export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
export PATH=$JAVA_HOME/bin:$PATH

# ── [3/8] Maven ──────────────────────────────────────────────────────────────
echo ""
echo "[3/8] Installation de Maven..."
sudo apt install -y maven
mvn -version

# ── [4/8] PostgreSQL ─────────────────────────────────────────────────────────
echo ""
echo "[4/8] Installation et démarrage de PostgreSQL..."
sudo apt install -y postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
sudo systemctl status postgresql --no-pager
echo "✅ PostgreSQL installé et démarré"

# ── [5/8] Node.js 18 LTS + npm ───────────────────────────────────────────────
# NOTE: 'sudo apt install npm' installe une version très ancienne (npm 6 / node 10)
# On installe Node.js 18 LTS via NodeSource pour compatibilité Angular moderne
echo ""
echo "[5/8] Installation de Node.js 18 LTS + npm..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs
node -v
npm -v

# ── [6/8] Téléchargement des archives projets ─────────────────────────────────
echo ""
echo "[6/8] Téléchargement des archives GMAO..."
cd ~
wget -q --show-progress http://n.grassa.free.fr/TD_devops/gmao-backend.tar.gz
wget -q --show-progress http://n.grassa.free.fr/TD_devops/gmao-frontend.tar.gz
echo "✅ Téléchargements terminés"

# ── [7/8] Décompression ───────────────────────────────────────────────────────
echo ""
echo "[7/8] Décompression des archives..."
tar xzf gmao-backend.tar.gz
tar xzf gmao-frontend.tar.gz
echo "✅ Décompression terminée"

# ── [8/8] Vérification ────────────────────────────────────────────────────────
echo ""
echo "[8/8] Vérification de la structure des projets..."
echo "--- gmao-backend ---"
ls -la ~/gmao-backend/
echo "--- gmao-frontend ---"
ls -la ~/gmao-frontend/

echo ""
echo "============================================"
echo "  POST-INSTALLATION TERMINÉE ✅  $(date)"
echo "============================================"
echo "Java    : $(java -version 2>&1 | head -1)"
echo "Maven   : $(mvn -version 2>&1 | head -1)"
echo "Psql    : $(psql --version)"
echo "Node    : $(node -v)"
echo "npm     : $(npm -v)"
