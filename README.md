# Cloudflare Dynamic DNS IP Updater
<img alt="GitHub" src="https://img.shields.io/github/license/Jeff-Enriquez/cloudflare-ddns-updater?color=black"> <img alt="GitHub last commit (branch)" src="https://img.shields.io/github/last-commit/Jeff-Enriquez/cloudflare-ddns-updater/main"> <img alt="GitHub contributors" src="https://img.shields.io/github/contributors/Jeff-Enriquez/cloudflare-ddns-updater">

> I have forked this repo for my own personal use. I reduced the number of api calls to CloudFlare. I spread the load to the IP services. I also removed the slack and discord features since I do not need them. If you manually update the CloudFlare IP address and are running the cron job. You will need to delete the OLD_IP_FILE.

This script is used to update Dynamic DNS (DDNS) service based on Cloudflare! Access your home network remotely via a custom domain name without a static IP! Written in pure BASH.

## Usage
This script is used with crontab. Specify the frequency of execution through crontab. My recommendation is every minute.
1. Use cloudflare-template.sh for IPv4. Update the variables for your CloudFlare account. This is a great video for finding those values - [NetworkChuck](https://www.youtube.com/watch?v=rI-XxnyWFnM&ab_channel=NetworkChuck).
2. Open the terminal.
3. Execute `chmod +x {file}`
   - Example: `chmod +x ./cloudflare.sh`
4. Execute `crontab -e` this will open up a file.
5. In the file enter `*/1 * * * * cd {directory - not filename} && /bin/sh ./{file}`. This will run the script every minute. Specifying the directory path allows the OLD_IP_FILE and IP_SERVICES_FILE to be created in the same folder as the sh file.
   - Example: `*/1 * * * * cd /home/jeff/cloudflare-ddns-updater && /bin/sh ./cloudflare.sh`
6. Close and save the file.
7. Execute `systemctl restart cron`. This will restart the cron service.

## Support The Original Creator
Shout out to the original creator of this project [Jason K](https://github.com/K0p1-Git). This is his link from when I cloned the repo.
[![Donate Via Paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.me/Jasonkkf)

### Reference
This script was made with reference from [Keld Norman](https://www.youtube.com/watch?v=vSIBkH7sxos) video.

## License
[MIT](https://github.com/K0p1-Git/cloudflare-ddns-updater/blob/main/LICENSE)