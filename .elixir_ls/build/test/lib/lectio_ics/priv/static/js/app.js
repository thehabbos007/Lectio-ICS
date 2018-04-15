class Calendar {
  constructor(url, weeks) {
    this.rawURL = url
    this.URL    = new URL(url)
    this.weeks  = weeks
  }

  getSchool() {
    let school = this.rawURL.match(/(\/\d+\/)/)

    return school[0]
  }

  getStudentID() {
    let student = this.URL.searchParams.get("elevid")

    return student
  }

  getWebcalLink() {
    let school  = this.getSchool()
    let student = this.getStudentID()
    let weeks   = this.weeks

    return `webcal://lectio-ics.herokuapp.com/api${school}${student}/${weeks}`
  }

}

let spinner = (setter) => {$(".spinner, .message").toggle(setter == true)}
let info    = (setter) => {$("#webcallink, #info").toggle(setter == true)}

var link = $("#link").val()
var weeks = $("#weeks").val()

let calc = () => {
  spinner(1);
  info(0);
  $("#go").prop("disabled", true);
  $(".result").html("");

  let calendar = new Calendar(link, parseInt(weeks));

  let webcalLink = calendar.getWebcalLink()
  console.log(webcalLink)

  setTimeout(() => { 
    spinner(0);
    $("#webcallink").text(webcalLink)
    info(1);
    $( "#go" ).prop( "disabled", false);
  }, 2500);
  
 
}

$("#go").click(function() {
  calc()
})

$("#go").keyup(function(e) {
    if (e.keyCode === 13) {
        calc()
    }
})