## vgitscraper
##a github scraper in vlang

## sometime you don't want to clone the whole content of a repository on the github, you may only be interested in some parts such as certain source code and pdf books etc.
## why vlang: it only took me around one day to know the grammar and syntex of vlang. it's really simple and straighforward, and as a brand new language the documentation is quite good. so it's very easy to put hands on and write up your code.
## currently you can use this tiny tool to download all files with extention passed as one of the args within a directory. so you need to copy the directory link to be another args, and also need to explicitly state where the downloaded file to be saved. the usage of it as following:
```
./gitscraper -u [url of github directory within where the file to be downloaded is located] -k [.file extension](pay attention to the dot) -d [local directory for downloaded file to save]
```
thanks for your attention, and cheers
