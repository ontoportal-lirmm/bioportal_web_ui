/**
 * @author palexander
 */

// Takes a jQuery selector list element where the elements have a value attribute set to the number of
// items that the element represents. It them sets the font size based on how far from the average
// that particular element's value is.
function createTagCloud(list) {
  var mapping_average = 0;

  // Total the values
  jQuery(list)
    .children()
    .each(function () {
      mapping_average += parseInt(jQuery(this).attr("value"));
    });

  // Get our average
  mapping_average = mapping_average / jQuery(list).children().size();

  // Set font sizes
  jQuery(list)
    .children()
    .each(function () {
      var percentage =
        (parseInt(jQuery(this).attr("value")) / mapping_average) * 150;
      percentage > 500 ? (percentage = 500) : (percentage = percentage);
      percentage < 125 ? (percentage = 125) : (percentage = percentage);
      jQuery(this).css("fontSize", percentage + "%");
    });
}
