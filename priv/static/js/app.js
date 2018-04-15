// Der oprettes en klasse Calendar, til at håndtere 
// ics linket fra APIet
class Calendar {
  // Constructoren sætter standardværdier 
  // for klassen
  constructor(url, weeks) {
    this.rawURL = url
    this.URL    = new URL(url)
    this.weeks  = weeks
  }

  // Diverse get-funktioner som anvendes indbyrdes
  getSchool() {
    let school = this.rawURL.match(/(\/\d+\/)/)

    return school[0]
  }

  getStudentID() {
    let student = this.URL.searchParams.get("elevid")

    return student
  }

  // Calendar klassens endelige funktion til at genere linket
  getWebcalLink() {
    let school  = this.getSchool()
    let student = this.getStudentID()
    let weeks   = this.weeks

    return `webcal://lectio-ics.herokuapp.com/api${school}${student}/${weeks}`
  }

}

// Mindre funktioner til at 
// skjule/vise diverse elementer på siden
// henholdsvis "loader" css annimationen samt
// selve tekstafsnittet
let spinner = (setter) => {$(".spinner, .message").toggle(setter == true)}
let info    = (setter) => {$("#webcallink, #info").toggle(setter == true)}

// Referencer til input tagsne, hvor lectio link og ugeantal indtastes
var linkTag = $("#link")
var weeksTag = $("#weeks")

let calc = () => {
  // spinner vises, og info skjules. Derudover sættes knappen til disabled
  spinner(1);
  info(0);
  $("#go").prop("disabled", true);

  // Her tjekkes værdien af ugeantal i ternary operators
  // ugeantallet skal være mellem 1 og 25, ellers sættes værdien til 3
  let weeks = (weeksTag.val() <= 0 || weeksTag.val() > 25 ) ? 3 : weeksTag.val()

  // Der oprettes en instans af Calendar klassen
  let calendar = new Calendar(linkTag.val(), parseInt(weeks));

  // og et link genreres fra de givne værdier
  let webcalLink = calendar.getWebcalLink()

  // falsk ventetid ti lat overbevise brugeren om at "der sker noget"
  setTimeout(() => { 
    // de visuelle elementer skjules/vises, og teksten opdateres
    spinner(0);
    $("#webcallink").text(webcalLink)
    info(1);
    $( "#go" ).prop( "disabled", false);
  }, 2500);
  
}


// Diverse hooks til enten at trykke på pilen eller enter  
// for at udregne linket
$("#go").click(function() {
  calc()
})

$("#go").keyup(function(e) {
    if (e.keyCode === 13) {
        calc()
    }
})