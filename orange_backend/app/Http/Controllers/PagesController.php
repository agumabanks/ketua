<?php

namespace App\Http\Controllers;

use App\Models\Pages;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PagesController extends Controller
{
    private function reader(string $title, ?string $content) {
        $html=preg_replace('/\borange\b/i','KETUA',$content??'');
        $dom=new \DOMDocument();
        $previous=libxml_use_internal_errors(true);
        $dom->loadHTML('<?xml encoding="UTF-8"><div>'.$html.'</div>', LIBXML_NONET);
        libxml_clear_errors();libxml_use_internal_errors($previous);
        $allowed=['html','body','div','p','br','h1','h2','h3','h4','strong','b','em','i','u','ul','ol','li','a','blockquote','hr','table','thead','tbody','tr','th','td'];
        foreach(iterator_to_array($dom->getElementsByTagName('*')) as $node) {
            if(!in_array(strtolower($node->nodeName),$allowed,true)) {$node->parentNode?->removeChild($node);continue;}
            foreach(iterator_to_array($node->attributes) as $attribute) {
                if($node->nodeName==='a' && $attribute->name==='href' && preg_match('#^(https://|mailto:)#i',$attribute->value)) continue;
                $node->removeAttribute($attribute->name);
            }
        }
        $body=$dom->getElementsByTagName('body')->item(0);$safe='';
        if($body) foreach($body->childNodes as $node) $safe.=$dom->saveHTML($node);
        return response()->view('pages.reader',['title'=>$title,'content'=>$safe,'available'=>trim(strip_tags($safe))!==''])
            ->header('Content-Security-Policy',"default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; frame-ancestors 'self'")
            ->header('X-Content-Type-Options','nosniff');
    }
    private function record(string $slug): ?Pages {
        return Pages::where('slug',$slug)->first();
    }
    public function privacypolicy(Request $request){
        $page=$this->record('privacy-policy');
        return $this->reader('Privacy policy', $page?->is_active ? $page->content : null);
    }
    public function termsOfUse(Request $request){
        $page=$this->record('terms-of-use');
        return $this->reader('Terms of use', $page?->is_active ? $page->content : null);
    }
    public function csae(){
        $page=$this->record('csae-standards');
        return $this->reader('Child safety standards (CSAE)', $page?->is_active ? $page->content : null);
    }
    public function viewPrivacy(){return view('pages.viewPrivacy',['data'=>$this->record('privacy-policy')?->content??'']);}
    public function viewTerms(Request $request){return view('pages.viewTerms',['data'=>$this->record('terms-of-use')?->content??'']);}
    private function updatePage(Request $request,string $slug,string $title){
        $v=$request->validate(['content'=>'required|string|max:100000','publish'=>'nullable|boolean']);
        $publish=$request->boolean('publish',true);
        if($publish && preg_match('/\[CONFIRM|Complete before publication|Draft — administrator review/iu',$v['content'])) throw \Illuminate\Validation\ValidationException::withMessages(['content'=>'Complete the draft company, contact and operational details before publishing.']);
        $page=$this->record($slug)??new Pages();
        $page->slug=$slug;$page->title=$title;$page->content=$v['content'];$page->is_active=$publish;$page->save();
        return response()->json(['status'=>true,'message'=>$publish?'Page published successfully.':'Review draft saved; not public.']);
    }
    public function updatePrivacy(Request $request){return $this->updatePage($request,'privacy-policy','Privacy policy');}
    public function updateTerms(Request $request){return $this->updatePage($request,'terms-of-use','Terms of use');}
}
