import net.http
import net.html
import os
import os.cmdline
import net.urllib
import sync

const ghr = 'https://raw.githubusercontent.com'
const gh = 'https://github.com'

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
	tid := sync.thread_id()
	println('[tid:$tid.hex()]: start donwload $df into $fd')
	http.download_file(df,fd)?
	wg.done()
	return 'done'
}

fn get_total_page_links(mut wg sync.WaitGroup, url string, keyword string, path string, dir string) ?{
	tid := sync.thread_id()
	mut content := http.get_text(url)
	document := html.parse(content)
	println('[tid:$tid.hex()]: start parse content...')
	anchor_tags := document.get_tag('a')
	println('[tid:$tid.hex()]: getting all hrefs...')
	mut retf := map[string]string{}
	mut retd := []string{}
	for tag in anchor_tags{
		if tag.attributes['href'].ends_with(keyword){
			println('[tid:$tid.hex()]: summarizing keyword files...')
			retf[tag.attributes['title']]=tag.attributes['href']
		}else if tag.attributes['href'].starts_with(path) && tag.attributes['href'].contains('tree/master/'){
			println('[tid:$tid.hex()]: related directory found: ${tag.attributes['href']}')
			retd << tag.attributes['href']
		}
	}
	aurl := urllib.parse(url)or{panic(err)}
	if retf.len>0{
		mut tempd := []string
		mut tempdir := ''
		for _,mut dv in retf{
			dv = dv.replace('blob','raw')
			if dv.contains('master'){
				tempd = (dv.split('master')[1]).split('/')
				tempdir = dir + tempd#[..-1].join('/')
			}else if dv.contains('main'){
				tempd = (dv.split('main')[1]).split('/')
				tempdir = dir + tempd#[..-1].join('/')
			}
			if !os.exists('./$tempdir/'){
				os.mkdir('./$tempdir/',os.MkdirParams{})?
				println('[tid:$tid.hex()]: dir ./$tempdir/ created')
			}
		}
	wg.add(retf.len)
	println('[tid:$tid.hex()]: ${retf.keys().len} file download wg created')
		for dk,mut dv in retf{
			go godf(mut wg, 'https://$aurl.host$dv', './$tempdir/$dk')
		}
		println('[tid:$tid.hex()]: all download done')
	}
	if retd.len>0{
	wg.add(retd.len)
	println('[tid:$tid.hex()]: ${retd.len} directory explore wg created, they are:')
		for link in retd{
			println(link)
			go get_total_page_links(mut wg,'https://$aurl.host$link',keyword,link.trim_right('/'),dir)
		}
		println('[tid:$tid.hex()]: all directory done')
	}
	wg.done()
	println('[tid:$tid.hex()]: all done')
	return
}

fn main(){
	mtid := sync.thread_id()
	if os.args.len <3{
		println('[mtid:$mtid.hex()]: usage: scrap -u [url] -k [keyword] -d [directory to save file]')
		return
	}
	base_url := cmdline.option(os.args[1..],'-u','')
	println('[mtid:$mtid.hex()]: url to analyze is: $base_url')
	url := urllib.parse(base_url)or{panic(err)}
	println('[mtid:$mtid.hex()]: host is: ${url.host}')
	path := url.path
	println('[mtid:$mtid.hex()]: path is: $path')
	keyword := cmdline.option(os.args[1..],'-k','')
	println('[mtid:$mtid.hex()]: keyword to search for file download is: $keyword')
	mut dir := cmdline.option(os.args[1..],'-d','')
	print('[mtid:$mtid.hex()]: directory to save is: $dir, ')
	if os.exists('./$dir'){
		println('[mtid:$mtid.hex()]: existed.')
	}else{
		os.mkdir('./$dir',os.MkdirParams{}) or {panic(err)}
		println('[mtid:$mtid.hex()]: not existed, just created.')
	}
	mut wg := sync.new_waitgroup()
	//mut i := 0
	wg.add(1)
	get_total_page_links(mut wg,base_url,keyword,path,dir)?
	wg.wait()
	println('[mtid:$mtid.hex()]: all done')
}