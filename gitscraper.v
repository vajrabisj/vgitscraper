import net.http
import net.html
import os
import os.cmdline
import net.urllib
import sync

const ghr = 'https://raw.githubusercontent.com/'
const gh = 'https://github.com/'

fn get_page_links(flink string) ?map[string]string {
	document := html.parse_file(flink)
	anchor_tags := document.get_tag('a')
	//println(anchor_tags)
	mut fileaddr := map[string]string{}
	for tag in anchor_tags {
		if 'class' in tag.attributes{ //&& tag.attributes['class'].contains('square')
			//println(tag)
			fileaddr[tag.attributes['title']]=tag.attributes['href']
		}else{
			println('no file found')
		}
	}
	return fileaddr
}

fn processing(p string, pdf bool,isf bool) string {
	mut plist := p.split('/')
	println('path split by / is: ${plist.str()}')
	mut newp := []string{}
	for i,e in plist{
		if i<=2{
			newp << e
		}
		if e=='master' || e=='main'{
			if pdf{
				newp << 'raw'
			}
			newp << plist[i..]
			/*newp << e
			for j:=i+1;j<plist.len;j++{
				newp << plist[j]
			}*/
			break
		}
	}
	if isf{
		return newp#[0..-1].join('/')
	}else{
		return newp.join('/')
	}
	
}

fn godf (mut wg sync.WaitGroup, df string, fd string) ?string{
	println('start donwload $df into $fd')
	http.download_file(df,fd)?
	wg.done()
	return 'done'
}

fn main(){
	if os.args.len <3{
		println('usage: scrap -u [url] -k [keyword] -d [directory to save file]')
		return
	}
	base_url := cmdline.option(os.args[1..],'-u','')
	println('url to analyze is: $base_url')
	url := urllib.parse(base_url)or{panic(err)}
	println('host is: ${url.host}')
	path := url.path
	println('path is: $path')
	keyword := cmdline.option(os.args[1..],'-k','')
	println('keyword to search for file download is: $keyword')
	mut ispdf := false
	if keyword=='.pdf'{
		ispdf = true
	}
	mut processedpath := urllib.parse(processing(path,ispdf,false))or{panic(err)}
	println('after processing, path is: $processedpath')
	dir := cmdline.option(os.args[1..],'-d','')
	print('directory to save is: $dir, ')
	if os.exists('./$dir'){
		println('existed.')
	}else{
		if ret := os.mkdir('./$dir',os.MkdirParams{}){
			println('not existed, just created.')
		}else{
			panic(err)
		}
	}
	mut content := http.get_text(base_url)
	os.write_file('./file.html',content)?
	mut wg := sync.new_waitgroup()
	mut df := map[string]string
	if ret := get_page_links('./file.html'){
		for k,v in ret{
			if os.file_ext(k) == keyword{
				println('$k : $v')
				if ispdf{
					processedpath = urllib.parse(processing(v,ispdf,true))or{panic(err)}
					println('prepare for download: $gh$processedpath/$k')
					//println('download start...')
					df['$gh$processedpath/$k']='./$dir/$k'
				}else{
					processedpath = urllib.parse(processing(v,ispdf,true))or{panic(err)}
					println('prepare for download: $ghr$processedpath/$k')
					//println('download count...')
					df['$ghr$processedpath/$k']='./$dir/$k'
				}
			}
		}
		wg.add(df.keys().len)
		println('${df.keys().len} wg created')
		for dk,dv in df{
			go godf(mut wg, dk, dv)
		}
		wg.wait()
		println('all done')
	}else{
		panic(err)
	}
}