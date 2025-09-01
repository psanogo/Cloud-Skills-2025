```
gsutil mb -c nearline gs://$Bucket_1


gcloud alpha storage buckets update gs://$Bucket_2 --no-uniform-bucket-level-access


gsutil acl ch -u $USER_EMAIL:OWNER gs://$Bucket_2


gsutil rm gs://$Bucket_2/sample.txt


echo "Cloud Storage Demo" > sample.txt


gsutil cp sample.txt gs://$Bucket_2


gsutil acl ch -u allUsers:R gs://$Bucket_2/sample.txt

```


gcloud storage buckets update gs://$Bucket_3 --update-labels=key=value
