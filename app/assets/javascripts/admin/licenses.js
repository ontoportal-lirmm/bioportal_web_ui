jQuery(".admin.index").ready(function() {

  jQuery('button[data-bs-toggle="tab"]').on('shown.bs.tab', function (e) {
    const target = jQuery(e.target).data('bsTarget');
    if (typeof target !== 'undefined' && target === '#licensing') {
      jQuery.ajax({
        method: 'GET',
        url: 'admin/licenses',
        success: function(data){},
        error: function(data){}
      });
    }
  });
});


