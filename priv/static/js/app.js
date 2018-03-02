// for phoenix_html support, including form and button helpers
// copy the following scripts into your javascript bundle:
// * https://raw.githubusercontent.com/phoenixframework/phoenix_html/v2.10.0/priv/static/phoenix_html.js
var spinner = function(){$(".spinner, .message").toggle()};
var info = function(){$("#link, #info").toggle()};

$("#go").click(function() {
  spinner();
  $("#go").prop( "disabled", false);
  $(".result").html("");
  let link = $("#val").val();
  let url = new URL(link);
  var school = link.match(/(\/\d+\/)/)[0]
  var user = url.searchParams.get("elevid");
  var linke = `webcal://lectio-ics.herokuapp.com/api${school}${user}/3`

  setTimeout(function(){ 
    spinner();
    $("#link").text(linke)
    info();
    $( "#go" ).prop( "disabled", false);
  }, 2500);
  
 
});