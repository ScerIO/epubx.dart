String combineHtmls(String? html1, String? html2){
  if(html1 != null && html2 != null){
    return html1 + '/n' + html2;
  }
  else{
    return (html1 ?? '') + (html2 ?? '');
  }
}