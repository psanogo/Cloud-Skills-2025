```
gsutil mb -c nearline gs://$Bucket_1

echo "This is an example of editing the file content for cloud storage object" | gsutil cp - gs://$Bucket_2/sample.txt

gsutil defstorageclass set ARCHIVE gs://$Bucket_3
```
