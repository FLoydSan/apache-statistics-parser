#!/bin/bash
tfile=/tmp/apache.log
sudo grep $(date '+%d/%b/%Y') /var/log/apache2/access.log >$tfile
thits=$(grep -c . $tfile)
echo "Content-type: text/html"
echo ""
echo "<html>
<head><title>Report for $(date '+%d/%b/%Y')</title></head>
<body>
<h1>Report for $(hostname) on $(date '+%d/%b/%Y')</h1>
<pre> "


echo "<b>Total hits :: $thits</b>"
echo ""
echo "<b>User agent distribution ::</b> "
#awk -F\" '{print $6}' $tfile  | sort | uniq -c | sort -fr

awk -F\" '{print $6}' $tfile | sed 's/(\([^;]\+; [^;]\+\)[^)]*)/(\1)/' |sort |uniq -c|sort -fr

echo "<BR><b>User response code:</b> "
awk 'BEGIN{
a[200]="OK";
a[206]="Partial Content";
a[301]="Moved Permanently";
a[302]="Found";
a[304]="Not Modified";
a[401]="Unauthorised (password required)";
a[403]="Forbidden";
a[404]="Not Found";
a[500]="Internal Server Error";
}
{print $9 " => <b>"a[$9]"</b>"}' $tfile | sort | uniq -c | sort -nr

echo "<BR><b>404 Error Summary::</b>"
awk '($9 ~ /404/)' $tfile | awk '{print $9,$7}' | sort | uniq -c|sort -nr|head -5

echo "<BR><b>IP Visit counts :: </b>"
awk '{print $1}' $tfile | grep -o "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" | sort -n | uniq -c | sort -nr|while read count ip
do
	name=$(echo $ip|/usr/bin/logresolve)
	printf "%5s\t%-15s\t%s\n" $count $ip $name
done


# cat $tfile |grep -o "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" | sort -nr | uniq -c | sort -n

echo "<BR><b>Top Agents ::</b> "
cat $tfile | awk -F\" '{print $6}'| sort -n | uniq -c | sort -nr |head -5

echo "<BR><b>Top urls ::</b>"
cat $tfile  | awk -F\" '{print $2}'| sort -n | uniq -c | sort -nr |head -5

echo -n "<BR><b>Total Bytes :::</b> "
cat $tfile | awk '{ sum += $10 } END { if ( sum > 1024*1024) {print sum/(1024*1024)"Mb"}else if ( sum > 1024) {print sum/1024"Kb";}else print sum }'

echo -n "<BR><b>Total Seconds ::</b> "
cat $tfile  | awk '{ sum += $13 } END { print sum }'
# sed 's/.*GET \(.*\) HTTP.*/\1/g' $tfile|awk -F/ '{if ( NF > 3 ) print $2"/"$3"/"$4; else print $2;}'|sort|uniq -c

echo "</body></pre></html>"
