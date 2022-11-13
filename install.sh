wget -N --no-check-certificate -q -O wulabing_install.sh "https://raw.githubusercontent.com/wulabing/V2Ray_ws-tls_bash_onekey/master/install.sh" && chmod +x wulabing_install.sh
echo "0 3 * * * /sbin/reboot" >> /var/spool/cron/crontabs/root
echo "*/20 * * * * /bin/sync && echo 3 > /proc/sys/vm/drop_caches" >> /var/spool/cron/crontabs/root
echo "0 3 1 * * bash /bin/systemctl stop nginx && /root/.acme.sh/acme.sh --renew-all --force && /bin/systemctl start nginx" >> /var/spool/cron/crontabs/root
