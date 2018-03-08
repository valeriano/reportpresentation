for ((i=1;i<=1;i++)); 

do   
curl -u admin:admin http://localhost:8080/job/Test/$i/api/xml/ >> $i.xml
done

