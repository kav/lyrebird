/**
 * @author kav
 */
$(document).ready(function(){
	$("#search").click(function(event){
		$.getJSON("http://search.twitter.com/search.json?callback=?", {q: $("input#query").val()}, function(data){
			$("#results > *").each(function(i){
				$(this).remove();
			});
			var htmlString = '';
			$.each(data.results, function(i,result){
				htmlString += "<span><a href=\"http://twitter.com/"+ result.from_user + ">" + result.from_user + "</a> " + result.text +"</span> <br/>";
			});
			$("#results").append(htmlString);
		});
		event.preventDefault();
		
	});
	$("#retweet").click(function(){
		$.getJSON("/retweet/" + $("#query").val(), function(storedQuery){
			$("#retweeting").contents().remove();
			$("#retweeting").append(storedQuery);
		});
	});
	$("#stoprt").click(function(){
		$.getJSON("/retweet/", function(storedQuery){
			$("#retweeting").contents().remove();
			$("#retweeting").append(storedQuery);
		});
	});
	$.getJSON("http://search.twitter.com/search.json?callback=?", {q: $("input#query").val()}, function(data){
			$.each(data.results, function(i,result){
				htmlString = "<span><a href=\"http://twitter.com/"+ result.from_user + ">" + result.from_user + "</a> " + result.text +"</span> <br/>";
				$("#results").append(htmlString);
			});		
	});
});