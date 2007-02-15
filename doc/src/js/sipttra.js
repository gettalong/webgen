function toogle( element ) {
  if (document.getElementById(element).style.display == "block") {
    document.getElementById(element).style.display = "none";
  } else {
    document.getElementById(element).style.display = "block";
  }
}
