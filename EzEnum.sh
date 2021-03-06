#!/bin/bash


#Terminal color variables; ec=end color (white) 
green="\e[32;1m"
bg="\e[35;1m"
red="\e[31;1m"
blue="\e[34;1m"
yellow="\e[33;1m"
ec="\e[0m"


#Check for dependencies, exit if any aren't installed
fig=$(which figlet | wc -l)
nm=$(which nmap | wc -l)
wf=$(which wfuzz | wc -l)
sc=$(which smbclient | wc -l)
xt=$(which xterm | wc -l)
ovpn=$(which openvpn | wc -l)
sl=$(ls /usr/share/SecLists 2>&1 > /dev/null | grep "cannot access" | wc -l)

if [ $sl == 1 ];then
	echo -e "${red}Error!${ec}"
	echo "SecLists is not in the /usr/share directory..."
	exit
fi

tools=( $fig $nm $wf $sc $xt $ovpn )
for bin in ${tools[@]}; do
	while [[ $bin == 0 ]]; do		
		echo -e "${red}Error!${ec}"
		if [ $fig == 0 ];then
			echo "Figlet is not installed (sudo apt install figlet)..."					
		fi
		if [ $nm == 0 ];then
			echo "Nmap is not installed (sudo apt install nmap)..."							
		fi
		if [ $wf == 0 ];then
			echo "WFuzz is not installed (sudo apt install wfuzz)..."					
		fi
		if [ $sc == 0 ];then
			echo "SMBClient is not installed (sudo apt install smbclient)..."			
		fi
		if [ $xt == 0 ];then
			echo "XTerm is not installed (sudo apt install xterm)..."
		fi
		if [ $ovpn == 0 ];then
			echo "OpenVPN is not installed (sudo apt install openvpn)..."						
		fi			
		exit
	done
done


#Banner
echo "========================================================================================="
figlet -c -f slant "EzEnum"
echo -e "				By: ${bg}D0p3B34t5${ec}" 
echo -e "\n				Version: ${blue}1.1.0 ${ec}"
echo "========================================================================================="


#Checking for root user
root=$(id -u)
if [  $root != 0 ];then
	echo -e "${red}Must run script as root user.\nSyntax: sudo ./EzEnum.sh ${ec}"
	exit
fi

#Initial prompts
read -p "[+] Are you doing a TryHackMe or HackTheBox machine? [HTB/THM]: " response
while true; do
	case $response in
		HTB) 
			break;;
		THM) 
			break;;
		htb)
			break;;
		thm)
			break;;
		*) 
			read -p 'Please response with "HTB" or "THM": ' response
	esac
done

read -p "[+] Which OS user will files/directories be saved to? (case-sensitive): " USER
while [[ $USER == "" ]]; do
	read -p "Please input a user on this machine: " USER
	if [ $USER > 1 ];then
		ok=1
	fi
done
while  [[ ! -d "/home/$USER" ]]; do
	read -p "Please provide a user that exists in the HOME directory: " USER
	while [[ $USER == "" ]]; do
		read -p "Please provide a user that exists in the HOME directory: " USER
		if [ $USER > 1 ];then
			ok=1
		fi
	done			
done  

read -p "[+] What is the machines name?: " tn
while [[ $tn == "" ]]; do
	read -p "Please provide a name for the machine: " tn
	if [ $tn > 1 ];then
		ok=1
	fi
done

read -p "[+] What is the machines IPv4 address?: " ti
while [[ $ti == "" ]]; do
	read -p "Please provide an IPv4 address for the machine: " ti
	if [ $ti > 1 ];then
		ok=1
	fi
done
while [[ ${#ti} -gt 15 ]]; do
	read -p "Please provide a valid IPv4 address: " ti
	if [ ${#ti} -le 15 ];then
		ok=1
	fi
done
while [[ $ti =~ ^[a-zA-Z]+$ ]]; do
	read -p "Please provide a valid IPv4 addresss: " ti
	while [[ $ti == "" ]]; do
		read -p "Please provide a valid IPv4 address: " ti
		if [ $ti -gt 1 ]; then
			ok=1
		fi
	done	
done
read -p "[+] Would you like to run a UDP scan? [Y/N]: " answer
while [ $answer == "" ]; do
	read -p 'Please respond with "Y" or "N": ' answer
	if [ $answer > 1 ];then
		ok=1
	fi
done
while true; do	
	case $answer in
		Y)
			break;;
		y)
			break;;
		N) 
			break;;
		n)
			break;;
		*)
			read -p 'Please respond with "Y" or "N": ' answer
	esac
done


#Setting site variable
if [[ $response == "HTB" || $response == "htb" ]];then
	site="HackTheBox"
elif
	[[ $response == "THM" || $response == "thm" ]];then
		site="TryHackMe"
fi


#Checking if connected to VPN, connect if not. Also check for multiple connections
interface=$(ifconfig | grep "tun" | cut -d ":" -f 1 | wc -l)
if [ $interface -ge 2 ];then
	read -p "More than 1 VPN interface detected. Which TUN interface is running your $site OVPN file? [0-2]: " int
	while true; do 
		case $int in
			0)
				break;;
			1)
				break;;
			2)
				break;;
			*)
				read -p "Please respond with 0-2: " int
		esac
	done
	vpn=$(ifconfig | grep "tun$int" | cut -d ":" -f 1 | wc -l)
else
	tun=$(ifconfig | grep "tun" | cut -d ":" -f 1 | wc -l)
	if [ $tun == 0 ];then
		vpn=0
	else
		vpn=$tun
	fi
fi

if [ $vpn == 1 ];then
	if [ $interface -ge 2 ];then
		tun="tun$int"
		myip=$(ifconfig $tun | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')
		echo -e "${green}VPN already connected...${ec}"
		sleep 1
		echo -e "${green}Your VPN IP address is: ${blue}$myip ${ec}"
		sleep 3
	else
		echo -e "${green}VPN already connected...${ec}"
		tun=$(ifconfig | grep "tun" | cut -d ":" -f 1)
		myip=$(ifconfig $tun | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')	
		sleep 1
		echo -e "${green}Your VPN IP address is: ${blue}$myip ${ec}"
		sleep 3
	fi
elif
	[ $vpn == 0 ];then
		echo -e "${green}[+] Attempting to connect to VPN... ${ec}"
		if [[ $response == "HTB" || $response == "htb" ]];then
			xterm -e openvpn /home/$USER/path/to/hackthebox.ovpn& #<---- Change this path to your HackTheBox OVPN file's path. Leave the /home/$USER, and the "&" at the end.
			sleep 5
			vpn=$(ifconfig | grep "tun0" | wc -l)
			if [ $vpn == 1 ];then
				echo -e "${green}[+] Successfully connected to VPN...${ec}"
				sleep 1
				myip=$(ifconfig tun0 | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')
				echo -e "${green}[+] Your VPN IP address is: ${blue}$myip ${ec}"
				sleep 3					
			elif
				[ $vpn == 0 ];then
					echo -e "${red}[+] Unable to connect to VPN..." 
					echo -e "[+] Check and make sure you changed your HackTheBox OVPN path on line 212..."
					echo -e "[+] Exiting script...${ec}" 
					exit
			fi
		elif
			[[ $response == "THM" || $response == "thm" ]];then
				xterm -e openvpn /home/$USER/path/to/tryhackme.ovpn& #<---- Change this path to your TryHackMe OVPN file's path. Leave the /home/$USER, and the "&" at the end.
				sleep 5
				vpn=$(ifconfig | grep "tun0" | wc -l)
				if [ $vpn == 1 ];then
					echo -e "${green}[+] Successfully connected to VPN...${ec}"
					sleep 1
					myip=$(ifconfig tun0 | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')
					echo -e "${green}[+] Your VPN IP address is: ${blue}$myip ${ec}"
					sleep 3			
			elif
				[ $vpn == 0 ];then
					echo -e "${red}[+] Unable to connect to VPN..."
					echo -e "[+] Check and make sure you changed your TryHackMe OVPN path on line 230..."
					echo -e "[+] Exiting script...${ec}"					
					exit
			fi
		fi 		
fi


#Clear terminal for main function
clear -x


#New Banner with variable output displayed
echo "========================================================================================="
figlet -c -f slant "EzEnum"
echo -e "				by: ${bg}D0p3B34t5${ec}"
echo -e "\n				Version: ${blue}1.1.0 ${ec}"
echo "========================================================================================="
echo "========================================================================================="
echo -e "[+] ${yellow}Site: ${ec}$site"
echo -e "[+] ${yellow}Machine: ${ec}$tn"
echo -e "[+] ${yellow}Machine IP: ${ec}$ti"
echo -e "[+] ${yellow}User: ${ec}$USER"
echo -e "[+] ${yellow}Folders: ${ec}/home/$USER/Documents/$site/$tn/"
echo -e "[+] ${yellow}Your VPN IP: ${blue}$myip ${ec}"
echo "========================================================================================="
echo "========================================================================================="


#Add to hosts file
echo -e "${green}[+] Adding IP to Hosts file...${ec}"
echo "$ti $tn"  >> /etc/hosts
sleep 1


#Test connection
echo -e "${green}[+] Pinging host...${ec}"
count=$(ping -c 4 $tn | grep icmp* | wc -l)
if [ $count != 4 ];then
	echo -e "${red}[+] Device responded to ${ec}$count ${red}out of 4 ICMP requests...${ec}" 
	sleep 1
	read -p "Would you like to continue anyways? (Select 'Y' if device doesn't respond to ICMP requests) [Y/N]: " continue
	while [[ $continue == "" ]]; do
		read -p 'Please respond with "Y" or "N": ' continue
		if [ $continue > 1 ];then
			ok=1
		fi		
	done
	while true; do	
		case $continue in
			Y)
				break;;
			y)
				break;;
			N) 
				break;;
			n)
				break;;
			*)
				read -p 'Please respond with "Y" or "N": ' continue
		esac
	done
	if [[ $continue == "Y" || $continue == "y" ]];then
		echo -e "${blue}[+] Continuing... ${ec}"
		sleep 2
		echo -e "${blue}[+] Will attempt an Nmap TCP/UDP scan with the ${ec}-Pn ${blue}switch... ${ec}"
		sleep 1
	elif 
		[[ $continue == "N" || $continue == "n" ]];then
			echo -e "${red}[+] Removing entry from hosts file... ${ec}"
			sleep 1
			grep -v "$tn" /etc/hosts > /tmp/tmp.txt && mv /tmp/tmp.txt /etc/hosts
			echo -e "${red}[+] Ending script... ${ec}"
			sleep 1
			exit 0
	fi
elif
	[ $count == 4 ];then
		echo -e "${green}[+] ${blue}$tn ${green}is responding to ICMP requests... ${ec}"
		sleep 1
fi


#Make main site directory 
echo -e "${green}[+] Checking for ${blue}$site ${green}directory... ${ec}"
sleep 1
if [[ $response == "HTB" || $response == "htb" ]];then
	if [ ! -d "/home/$USER/Documents/$site" ];then
		echo -e "${green}[+] Creating main HackTheBox directory... ${ec}"
		sleep 1
		mkdir /home/$USER/Documents/$site
	else
		echo -e "${green}[+] Main directory already exists. Continuing... ${ec}"
		sleep 1
	fi
elif 
	[[ $response == "THM" || $response == "thm" ]];then
		if [ ! -d "/home/$USER/Documents/$site" ];then
			echo -e "${green}[+] Creating main TryHackMe directory... ${ec}"
			mkdir /home/$USER/Documents/$site
			sleep 1
		else 
			echo -e "${green}[+] Main directory already exists. Continuing... ${ec}"
			sleep 1
		fi
fi
	
	
#Make sub-directories	
if [[ $response == "HTB" || $response == "htb" ]];then
	if [ ! -d "/home/$user/Documents/HackTheBox/$tn" ];then
		echo -e "${green}[+] Creating main directory, and sub-directories in the ${blue}HTB ${green}directory... ${ec}"
		mkdir /home/$USER/Documents/HackTheBox/$tn
		mkdir /home/$USER/Documents/HackTheBox/$tn/enumeration
		mkdir /home/$USER/Documents/HackTheBox/$tn/exploitation
		mkdir /home/$USER/Documents/HackTheBox/$tn/post-exploitation
		sleep 1
	fi
elif 
	[[ $response == "THM" || $response == "thm" ]];then 
		if [ ! -d "/home/$USER/Documents/TryHackMe/$tn" ];then
			echo -e "${green}[+] Creating main directory, and sub-directories in the ${blue}THM ${green}directory... ${ec}"
			mkdir /home/$USER/Documents/TryHackMe/$tn
			mkdir /home/$USER/Documents/TryHackMe/$tn/enumeration
			mkdir /home/$USER/Documents/TryHackMe/$tn/exploitation
			mkdir /home/$USER/Documents/TryHackMe/$tn/post-exploitation
			sleep 1
		fi
fi

	
#Nmap TCP scan
if [[ $continue == "Y" || $continue == "y" ]];then	
	echo -e "${green}[+] Scanning for open ports on ${blue}$tn${green}...${ec}"
	sleep 1
	open=$(nmap -T4 --min-rate 750 -p- -Pn $tn | grep ^[0-9] | cut -d '/' -f 1 | sed -e '$!s/$/,/' | tr -d '\n')
	echo -e "${green}[+] Starting Nmap SYN scan against open ports... ${ec}"
	nmap -sS -sV -A -T4 -p $open -Pn $tn 1>/home/$USER/Documents/$site/$tn/enumeration/nmapresults.txt 2>&1
	echo -e "${green}[+] Nmap SYN scan results saved to ${red}/Documents/$site/$tn/enumeration/nmapresults.txt"			
elif
	[[ -z "$continue" ]];then
		echo -e "${green}[+] Scanning for open ports on ${blue}$tn${green}...${ec}"
		sleep 1
		open=$(nmap -T4 --min-rate 750 -p- $tn | grep ^[0-9] | cut -d '/' -f 1 | sed -e '$!s/$/,/' | tr -d '\n')
		echo -e "${green}[+] Starting Nmap SYN scan against open ports... ${ec}"
		nmap -sS -sV -A -T4 -p $open $tn 1>/home/$USER/Documents/$site/$tn/enumeration/nmapresults.txt 2>&1
		echo -e "${green}[+] Nmap SYN scan results saved to ${red}/Documents/$site/$tn/enumeration/nmapresults.txt"	
fi


#Nmap result variables
ws=$(grep ^[0-9] /home/$USER/Documents/$site/$tn/enumeration/nmapresults.txt | grep "80/tcp" | grep -v "8080" | wc -l)
ws8=$(grep ^[0-9] /home/$USER/Documents/$site/$tn/enumeration/nmapresults.txt | grep "8080/tcp" | wc -l)
wss=$(grep ^[0-9] /home/$USER/Documents/$site/$tn/enumeration/nmapresults.txt | grep "443/tcp" | wc -l)
smb=$(grep ^[0-9] /home/$USER/Documents/$site/$tn/enumeration/nmapresults.txt | grep "445/tcp" | wc -l)


#Nmap UDP scan
if [[ $continue == "Y" || $continue == "y" ]];then
	if [[ $answer == "Y" || $answer == "y" ]];then
		echo -e "${green}[+] Starting Nmap UDP Scan against top 50 ports... ${ec}"
		nmap -sU --top-ports 50 -Pn $tn 1>/home/$USER/Documents/$site/$tn/enumeration/nmapudpresults.txt 2>&1
		echo -e "${green}[+] Nmap UDP results saved to ${red}/Documents/$site/$tn/enumeration/nmapudpresults.txt ${ec}"
		sleep 1
	elif	
		[[ $answer == "N" || $answer == "n" ]];then
			echo -e "${green}[+] Skipping UDP scan... ${ec}"
			sleep 1
	
	fi
elif
	[[ -z "$continue" ]];then
		if [[ $answer == "Y" || $answer == "y" ]];then
			echo -e "${green}[+] Starting Nmap UDP Scan against top 50 ports... ${ec}"
			nmap -sU --top-ports 50 $tn 1>/home/$USER/Documents/$site/$tn/enumeration/nmapudpresults.txt
			echo -e "${green}[+] Nmap UDP results saved to ${red}/Documents/$site/$tn/enumeration/nmapudpresults.txt ${ec}"
			sleep 1
		elif	
			[[ $answer == "N" || $answer == "n" ]];then
				echo -e "${green}[+] Skipping UDP scan... ${ec}"
				sleep 1
		fi
fi


#WFuzz directory scan
if [[ $ws == 1 || $wss == 1 || $ws8 == 1 ]];then
	if [ $ws == 1 ];then
		echo -e "${green}[+] Port 80 is open, starting WFuzz directory scan on ${blue}$tn${green}:80... ${ec}"
		wfuzz -t 30 --req-delay 10 -w /usr/share/SecLists/Discovery/Web-Content/directory-list-2.3-small.txt -u http://$tn:80/FUZZ 1>/home/$USER/Documents/$site/$tn/enumeration/wfuzzdir80results.txt 2>&1
		echo -e "${green}[+] WFuzz results for port 80 saved in ${red}/Documents/$site/$tn/enumeration/wfuzzdir80results.txt ${ec}"
		sleep 1
	fi
	if [ $wss == 1 ];then
		echo -e "${green}[+] Port 443 is open, starting WFuzz directory scan on ${blue}$tn${green}:443... ${ec}"
		wfuzz -t 30 --req-delay 10 -w /usr/share/SecLists/Discovery/Web-Content/directory-list-2.3-small.txt -u http://$tn:443/FUZZ 1>/home/$USER/Documents/$site/$tn/enumeration/wfuzzdir443results.txt 2>&1
		echo -e "${green}[+] WFuzz results for port 443 saved in ${red}/Documents/$site/$tn/enumeration/wfuzzdir443results.txt ${ec}"
		sleep 1
	fi
	if [ $ws8 == 1 ];then
		echo -e "${green}[+] Port 8080 is open, starting WFuzz directory scan on ${blue}$tn${green}:8080... ${ec}"
		wfuzz -t 30 --req-delay 10 -w /usr/share/SecLists/Discovery/Web-Content/directory-list-2.3-small.txt -u http://$tn:8080/FUZZ 1>/home/$USER/Documents/$site/$tn/enumeration/wfuzzdir8080results.txt 2>&1
		echo -e "${green}[+] WFuzz results for port 8080 saved in ${red}/Documents/$site/$tn/enumeration/wfuzzdir8080results.txt ${ec}"
		sleep 1
	fi		
else
	echo -e "${green}[+] Ports 80/443/8080 do not appear to be open. Skipping directory scan ${ec}"
	sleep 1
fi


#WFuzz subdomain scan
if [[ $ws == 1 || $wss == 1 || $ws8 == 1 ]];then
	if [ $ws == 1 ];then
		echo -e "${green}[+] Scanning for subdomains on ${blue}$tn${green}:80... ${ec}"
		wfuzz -c -w /usr/share/SecLists/Discovery/DNS/subdomains-top1million-5000.txt -u http://$tn:80 -H "Host: FUZZ.$tn" 1>/home/$USER/Documents/$site/$tn/enumeration/subdomains80.txt 2>&1
		echo -e "${green}[+] Subdomain results for port 80 saved in ${red}/Documents/$site/$tn/enumeration/subdomains80.txt ${ec}"
		sleep 1
	fi
	if [ $wss == 1 ];then
		echo -e "${green}[+] Scanning for subdomains on ${blue}$tn${green}:443... ${ec}"
		wfuzz -c -w /usr/share/SecLists/Discovery/DNS/subdomains-top1million-5000.txt -u http://$tn:443 -H "Host: FUZZ.$tn" 1>/home/$USER/Documents/$site/$tn/enumeration/subdomains443.txt 2>&1
		echo -e "${green}[+] Subdomain results for port 443 saved in ${red}/Documents/$site/$tn/enumeration/subdomains443.txt ${ec}"
		sleep 1
	fi
	if [ $ws8 == 1 ];then
		echo -e "${green}[+] Scanning for subdomains on ${blue}$tn${green}:8080... ${ec}"
		wfuzz -c -w /usr/share/SecLists/Discovery/DNS/subdomains-top1million-5000.txt -u http://$tn:8080 -H "Host: FUZZ.$tn" 1>/home/$USER/Documents/$site/$tn/enumeration/subdomains8080.txt 2>&1
		echo -e "${green}[+] Subdomain results for port 8080 saved in ${red}/Documents/$site/$tn/enumeration/subdomains8080.txt ${ec}"
		sleep 1
	fi
else
	echo -e "${green}[+] Ports 80/443/8080 do not appear to be open. Skipping subdomain scan... ${ec}"
fi

	
#List SMB shares
if [ $smb == 1 ];then
	echo -e "${green}[+] Port 445 is open, listing shares... ${ec}"	 
	smbclient -L \\\\$tn\\ -N > /home/$USER/Documents/$site/$tn/enumeration/shares.txt 2>&1
	sleep 1
	echo -e "${green}[+] SMB list saved to ${red}/$site/$tn/enumeration/shares.txt ${ec}"
	sleep 1
else
	echo -e "${green}[+] Port 445 does not appear to be open, no shares to list... ${ec}"
	sleep 1
fi

echo -e "${blue}[+] Script Complete.... #EzLife ${ec}"
