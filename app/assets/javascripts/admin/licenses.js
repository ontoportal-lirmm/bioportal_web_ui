jQuery(".admin.index").ready(function () {
  jQuery('a[data-toggle="tab"]').on("shown.bs.tab", function (e) {
    var href = jQuery(e.target).data("href");
    if (typeof href !== "undefined" && href === "/admin/licenses") {
      jQuery.ajax({
        method: "GET",
        url: href,
        success: function (data) {},
        error: function (data) {},
      });
    }
  });
});
