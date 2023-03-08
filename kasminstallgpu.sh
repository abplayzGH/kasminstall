# update OS
sudo apt-get update
sudo apt-get upgrade -y


sudo apt install docker.io docker-compose -y

# install dependencies for nvidia driver
sudo apt-get upgrade -y linux-aws
sudo apt-get install -y gcc make linux-headers-$(uname -r)

# blacklist kernel modules that might interfere
cat << EOF | sudo tee --append /etc/modprobe.d/blacklist.conf
blacklist vga16fb
blacklist nouveau
blacklist rivafb
blacklist nvidiafb
blacklist rivatv
EOF
echo 'GRUB_CMDLINE_LINUX="rdblacklist=nouveau"' | sudo tee --append /etc/default/grub
sudo update-grub

# download latest driver, you may use a different method of obtaining the driver, this method uses the AWS CLI
sudo apt install -y awscli
aws s3 cp --no-sign-request  --recursive s3://ec2-linux-nvidia-drivers/latest/ .
chmod +x NVIDIA-Linux-x86_64*.run

# install
sudo /bin/sh ./NVIDIA-Linux-x86_64*.run -s

# check that card0 and renderD128 exist
ls /dev/dri

# check that nvidia-smi is working, it should report the driver and cuda version and card type
nvidia-smi


cd /tmp
curl -O https://kasm-static-content.s3.amazonaws.com/kasm_release_1.12.0.d4fd8a.tar.gz
tar -xf kasm_release_1.12.0.d4fd8a.tar.gz
sudo bash kasm_release/install.sh

# Install the NVIDIA Container Toolkit
distribution=$(. /etc/os-release;echo $ID$VERSION_ID) && curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add - && curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt-get update
sudo apt-get install -y nvidia-docker2
sudo systemctl restart docker

# depending on the configuration of your docker daemon, you may need to restart the Kasm agent container
sudo docker restart kasm_agent


if [ -f /opt/VirtualGL/bin/vglrun ] && [ ! -z "\${KASM_EGL_CARD}" ] && [ ! -z "\${KASM_RENDERD}" ] && [ -O "\${KASM_RENDERD}" ] && [ -O "\${KASM_EGL_CARD}" ] ; then
    echo "Starting Chrome with GPU Acceleration on EGL device \${KASM_EGL_CARD}"
    vglrun -d "\${KASM_EGL_CARD}" /opt/google/chrome/google-chrome ${CHROME_ARGS} "\$@"
else
    echo "Starting Chrome"
    /opt/google/chrome/google-chrome ${CHROME_ARGS} "\$@"
fi
