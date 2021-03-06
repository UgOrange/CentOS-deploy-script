# install zsh
# install plugins
# install vim
# install docker
# install ---

#检查是否为root
if [ ${USER}h != rooth ]
then
		echo "you are not root"
		exit 2
fi


print_help(){
  echo "This is a script for deploy CentOS on bootstrap"
  echo 
  echo -e "\targs"
  echo -e "  \t\t-c  activate mod for chinese user"
  echo -e "  \t\t-d  activate docker installation"
  echo -e "  \t\t-z  activate oh-my-zsh installation"
  echo -e "  \t\t-a  activate all with chinese mod"
  echo -e "  \t\t-p  activate python3.6 installation"
  echo -e "  \t\t-g  activate golang installation"
  echo -e "  \t\t-v  activate vim-config installation"
  echo -e "  \t\t-b  activate all but not in chinese mod"
  echo -e "  \t\t-h  print this help"
}

if [ $# -eq 0 ]
then
    print_help
fi


## init args
init_args(){
  # empty for now
  echo ""
  docker_on=0
  ohmyzsh_on=0
  ch_mod=0
  go_on=0
  python36_on=0
  vim_config_on=0
}

init_args 



while getopts "abcdghpvz" arg #选项后面的冒号表示该选项需要参数
do
    case $arg in
        c)
      ch_mod=1
			echo "In Ch' mod\n"
			;;
        h)
        print_help
        exit 0
        ;;
        a)
        ch_mod=1
        docker_on=1
        ohmyzsh_on=1
        go_on=1
        python36_on=1
        vim_config_on=1
        ;;
        b)
        docker_on=1
        ohmyzsh_on=1
        go_on=1
        python36_on=1
        vim_config_on=1
        ;;
        g)
        go_on=1
        ;;
        v)
        vim_config_on=1
        ;;
        z)
        ohmyzsh_on=1
        ;;
        p)
        python36_on=1
        ;;
        d)
        docker_on=1
        ;;
        ?)  #当有不认识的选项的时候arg为?
			echo "unkonw argument"
			exit 1
		;;
    esac
done




echo "****sleep 5 sec before starting installation****\n"
sleep 5


only_if(){
  # execute $2 only when $1 is set to none zero
  # echo $3 at the same time as discription (optional)
  
  if [ $1 -ne 0 ]
  then
  echo $3
  $2
  fi
}


replace_source_ch(){

# prerequest
yum install -y autoload

# backup
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak

cat > /etc/yum.repos.d/CentOS-Base.repo <<EOF
[base]
name=CentOS-\$releasever - Base
#mirrorlist=http://mirrorlist.centos.org/?release=\$releasever&arch=\$basearch&repo=os
baseurl=https://mirrors.ustc.edu.cn/centos/\$releasever/os/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#released updates
[updates]
name=CentOS-\$releasever - Updates
# mirrorlist=http://mirrorlist.centos.org/?release=\$releasever&arch=\$basearch&repo=updates
baseurl=https://mirrors.ustc.edu.cn/centos/\$releasever/updates/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#additional packages that may be useful
[extras]
name=CentOS-\$releasever - Extras
# mirrorlist=http://mirrorlist.centos.org/?release=\$releasever&arch=\$basearch&repo=extras
baseurl=https://mirrors.ustc.edu.cn/centos/\$releasever/extras/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#additional packages that extend functionality of existing packages
[centosplus]
name=CentOS-\$releasever - Plus
# mirrorlist=http://mirrorlist.centos.org/?release=\$releasever&arch=\$basearch&repo=centosplus
baseurl=https://mirrors.ustc.edu.cn/centos/\$releasever/centosplus/\$basearch/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
EOF
  yum makecache
}



    

init(){
  yum -y update
}

install_basic(){
  yum install -y -q zsh vim curl vim-enhanced axel iftop htop nload git jq bridge-utils wget

  yum install -y yum-utils \
           device-mapper-persistent-data \
           lvm2

  yum install -y epel-release
  yum install --enablerepo=epel python2-pip -y
}


install_docker_ch(){
  cat > /etc/docker/daemon.json << EOF
{
  "registry-mirrors": ["https://docker.mirrors.ustc.edu.cn/"]
}
EOF
}

install_docker(){
  echo ##########################################
  echo #
  echo #     start to install docker 
  echo #
  echo ##########################################

  curl -fsSL https://get.docker.com/ | sh

  groupadd docker
  usermod -aG docker $USER

  only_if $ch_mod install_docker_ch "Change source for docker"
  sed -i 's/enforcing/disabled/' /etc/selinux/config  
  systemctl start docker
  systemctl restart docker
  docker pull php
  docker pull node
  docker pull nginx
  docker pull mariadb
  docker pull centos
  docker pull phpmyadmin/phpmyadmin
  docker pull alpine

  # install dry-bin
  curl -sSf https://moncho.github.io/dry/dryup.sh | sudo sh
  sudo chmod 755 /usr/local/bin/dry

 
  
}



install_ohmyzsh(){
  echo ##########################################
  echo #
  echo #     start to install oh-my-zsh 
  echo #
  echo ##########################################

# install oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

# install zsh-autosuggestion
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
# install zsh-syntax-highlighting
git clone https://github.com/zdharma/fast-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting

# install docker-machine for oh-my-zsh plugins
git clone https://github.com/leonhartX/docker-machine-zsh-completion.git ~/.oh-my-zsh/custom/plugins/docker-machine

# copy .zshrc to ~/


if [ -f "./zshrc-config" ]
then
  if [ -f "~/.zshrc" ]
  then
  mv ~/.zshrc ~/.zshrc.bak
  fi
cp ./zshrc-config ~/.zshrc
fi

# change default shell
chsh -s /bin/zsh root


source ~/.zshrc
}


install_go(){
  echo ##########################################
  echo #
  echo #     start to install go 
  echo #
  echo ##########################################

  # install go
  yum install -y go
  go get -u github.com/jingweno/ccat
}

install_docker_compose(){
  # require pip
  pip install docker-dompose
}

install_python36(){
  echo ##########################################
  echo #
  echo #     start to install python3.6 
  echo #
  echo ##########################################

  yum install --enablerepo=epel -y python36 python36-setuptools
  easy_install-3.6 pip

  only_if $docker_on install_docker_compose "\n\ninstall docker-compose\n\n"
}

install_vim_config(){
  echo ##########################################
  echo #
  echo #     start to install vim_config 
  echo #
  echo ##########################################

  curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

  echo ##########################################
  echo #
  echo #     Then you should past your custom vimrc
  echo #
  echo ##########################################
}



main(){
  only_if $ch_mod replace_source_ch "\n\nfor chinese user\n\n"
  init
  install_basic
  only_if $docker_on install_docker "\n\ninstall docker\n\n"
  only_if $ohmyzsh_on install_ohmyzsh "\n\ninstall olmyzsh\n\n"
  only_if $go_on install_go "\n\ninstall go\n\n"
  only_if $python36_on install_python36 "\n\ninstall python3.6\n\n"
  only_if $vim_config_on install_vim_config "\n\ninstall vim_config\n\n"
}


main