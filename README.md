# EzEnum v1.1.0
 

![image](https://user-images.githubusercontent.com/98996357/167476640-21c8519a-9364-4e23-98ab-99ce9cd3e89a.png)




 ## What is EzEnum?
 EzEnum is a simple bash script to automate organization and repetetive tasks when doing TryHackMe or HackTheBox machines.
 
 ### Note: 
 - This is the first script I've ever written so I appreciate all feedback. I have only tested this on Kali Linux and Linux Mint, though most of the dependencies are in the default apt repository so it should work on most distributions that use apt as the package manger
 - EzEnum needs to be ran as the root user to allow the script to run it's course with no issues. When EzEnum asks which OS user you would like to use for this script, the user needs to be in the Home directory, with a 'Documents' directory present as this is where the Machines main, and sub-directories will be written to. 
 
 
## What EzEnum does...
EzEnum will perform the following:
- Will automatically connect to your HackTheBox/TryHackMe VPN connection respectively
  #### IMPORTANT: 
   - **You will have to edit the script to supply the path to your TryHackMe/HackTheBox OVPN file.**
   - Edit the path on line **212** and provide path to HackTheBox OVPN
   - Edit the path on line **230** and provide path to TryHackMe OVPN                   
    ![image](https://user-images.githubusercontent.com/98996357/167472486-d592321c-fceb-422b-bdc2-8fbf26aec7e8.png)
    ![image](https://user-images.githubusercontent.com/98996357/167472557-d1824324-ab9e-441b-832a-0aa800d8e4cd.png)
- Will check to make sure all dependencies are installed and that SecLists is in the /usr/share directory
- Ask whether you're doing a TryHackMe or HackTheBox machine, create a main directory using the machines name, and sub-directories with that to provide organization to the files you may come across throughout the different stages of the machine
  - Sub-directories:
    - Enumeration
    - Exploitation
    - Post-exploitation

- Will take the machines name and IP, and add it to the hosts file
- Will ping the machine to make sure it can communicate with it
   - If the machine you're testing on doesn't respond to ICMP requests, you will have the option to continue and run your Nmap scans with the no ping switch 
- Will perform an Nmap TCP-SYN scan against all 65,535 ports on the machine, and output the results to a text file in the 'enumeration' directory
- Will perform an Nmap UDP scan against the top 50 ports, and output the results to a text file in the 'enumeration' directory
  - Optional; you get the decision at the beginning of the script to skip this if you want
- Will perform a directory scan using WFuzz if ports 80, 8080 or 443 are open, and output the results to a text file in the 'enumeration' directory
- Will perform a subdomain scan using WFuzz if ports 80, 8080 or 443 are open, and output the results to a text file in the 'enumeration' directory
- Will attempt to list available shares using SMBClient if port 445 is open, and output the results to a text file in the 'enumeration' directory




## Dependencies:
  - **WFuzz**
     -     sudo apt install wfuzz
  - **SecLists** (for wordlist, SecLists directory should be in the /usr/share directory for this script)
     - I used Git to install SecLists
        -     sudo apt install git
              sudo git clone https://github.com/danielmiessler/SecLists.git
              sudo mv SecLists/ /usr/share/SecLists   
  - **Nmap**
     -     sudo apt install nmap

  - **SMBClient**
     -     sudo apt install smbclient
 
  - **Figlet** (for the banner)
    -     sudo apt install figlet

  - **OpenVPN** 
    -     sudo apt install openvpn
   
  - **XTerm** 
    -     sudo apt install xterm
      

## Usage
  - EzEnum should be ran as the super user
      -     sudo ./EzEnum.sh


### Disclaimer
Creator is not responsible for the unlawful use of this tool. This tool is to be used for educational purposes only.
