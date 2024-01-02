#!/bin/bash;
set -e; for arg in "$@"; do case $arg in --aws-access-key=*) aws_access_key="${arg#*=}";; --aws-access-secret=*) aws_secret_access_key="${arg#*=}";; --s3-bucket=*) s3_bucket="${arg#*=}";; esac; done; function say { color=$1; message=$2; echo "Info: $(tput setaf $color)$message$(tput sgr0)"; }; function handle_error { say 1 "Error: $1"; exit 1; }; function command_exists { command -v "$1" >/dev/null 2>&1; }; function install_zip { if ! command_exists zip; then say 4 "Installing zip..."; sudo apt-get update; sudo apt-get install -y zip; say 2 "zip installed successfully."; else say 2 "zip is already installed."; fi; }; function install_s3fs { if ! command_exists s3fs; then say 4 "Installing s3fs..."; sudo apt-get update; sudo apt-get install -y s3fs; say 2 "s3fs installed successfully."; else say 2 "s3fs is already installed."; fi; }; function download_and_unzip { repo_url=$1; destination=$2; [ -d "$destination" ] && rm -r "$destination" ; mkdir "$destination" || mkdir "$destination"; say 4 "Downloading and extracting GitHub repository..."; curl -sSL $repo_url -o repo.zip; unzip -qq repo.zip -d $destination; rm repo.zip; }; function create_directory { directory=$1; say 4 "Creating directory: $directory"; sudo mkdir -p $directory; }; function mount_s3_bucket { directory=$1; aws_access_key=$2; aws_secret_access_key=$3; s3_bucket=$4; say 4 "Mounting S3 bucket..."; echo "$aws_access_key:$aws_secret_access_key" > ~/.passwd-s3fs; chmod 600 ~/.passwd-s3fs; s3fs $s3_bucket $directory -o passwd_file=~/.passwd-s3fs -o url=https://s3.amazonaws.com; sudo mount -a; say 2 "S3 bucket mounted successfully."; }; function show_bold_bi_graphic { echo ""; echo "██████╗   ██████╗  ██╗      ███████╗     ██████╗  ████████╗ "; echo "██╔══██╗ ██╔═══██╗ ██║      ██╔═══██╗    ██╔══██╗   ╚██╔══╝ "; echo "██████╔╝ ██║   ██║ ██║      ██║   ██║    ██████╔╝    ██║    "; echo "██╔══██╗ ██║   ██║ ██║      ██║   ██║    ██╔══██╗    ██║    "; echo "██████╔╝ ╚██████╔╝ ███████╗ ███████╔╝    ██████╔╝ ████████╗ "; echo " ╚════╝   ╚═════╝  ╚══════╝  ╚═════╝      ╚════╝   ╚══════╝ "; echo ""; }; function Install_k0s { say 4 "Installing k0s..."; if command_exists k0s; then say 2 "k0s is already installed."; else curl -sSLf https://get.k0s.sh | sudo sh; fi; }; function start_k0s { if ! k0s kubectl get nodes &> /dev/null; then say 4 "Starting k0s cluster..."; sudo k0s install controller --single & sleep 5 & sudo k0s start & sleep 10; fi; }; function install_boldbi { if [ -n "$aws_access_key" ] && [ -n "$aws_secret_access_key" ] && [ -n "$s3_bucket" ]; then install_s3fs; create_directory $directory; mount_s3_bucket $directory "$aws_access_key" "$aws_secret_access_key" "$s3_bucket"; else say 3 "Skipping S3 bucket mounting details are not provided."; fi; install_zip; Install_k0s; start_k0s; if ! k0s kubectl get nodes &> /dev/null; then handle_error "k0s cluster is not running."; fi; repo_url="https://github.com/sivakumar-devops/k0s-deploy/raw/main/private-cloud.zip"; destination="/manifest"; download_and_unzip $repo_url $destination; say 4 "Deploying Bold BI application..."; k0s kubectl apply -k $destination/private-cloud; show_bold_bi_graphic; say 2 "Bold BI application deployed successfully!"; say 4 "You can access "boldbi" on your machine's IP with port number 30080, and Redis on port 32379."; }; install_boldbi
