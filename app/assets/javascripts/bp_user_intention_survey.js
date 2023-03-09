function UserIntentionSurvey(options) {
  if (typeof options === "undefined") {
    return;
  }

  var self = this;
  self.surveyName = options.surveyName;
  self.forwardOnSubmit = options.forwardOnSubmit == true ? true : false;
  self.forwardToUrl = options.forwardToUrl;
  self.submitForAnalytics = options.submitForAnalytics == false ? false : true;
  self.tempDisableLength = options.tempDisableLength || 7;
  self.surveyEnabled = self.surveyName == "" ? false : true;
  self.timeoutKey = "user_survey_timeout_" + self.surveyName;

  self.bindTracker = function () {
    if (BP_getCookie(self.timeoutKey) === "true" || !self.surveyEnabled) {
      return false;
    }

    var path = window.location.pathname.split("/");
    if (path.length > 2) return false;

    jQuery.get("/home/user_intention_survey", function (data) {
      jQuery.facebox(data, "user_intention_survey");
    });

    jQuery(document).live("afterClose.facebox", function () {
      if (jQuery("#dont_show_again").is(":checked")) {
        self.disablePermanently();
      } else {
        self.disableTemporarily();
      }
      if (self.submitForAnalytics) {
        self.submitSurvey();
      }
    });

    jQuery("#intention_submit").live("click", function () {
      if (self.forwardToUrl) {
        self.disablePermanentlyAndForward(self.forwardToUrl);
      } else {
        self.closeDialog();
      }
    });

    jQuery("#intention_remind").live("click", function () {
      self.closeDialog();
    });

    jQuery("#intention_close").live("click", function () {
      self.closeDialog();
    });
  };

  self.disablePermanentlyAndForward = function (url) {
    BP_setCookie(self.timeoutKey, true, { days: 365 });
    setTimeout(function () {
      document.location = url;
    }, 500);
  };

  self.disablePermanently = function () {
    BP_setCookie(self.timeoutKey, true, { days: 365 });
  };

  self.disableTemporarily = function () {
    BP_setCookie(self.timeoutKey, true, { days: self.tempDisableLength });
  };

  self.closeDialog = function () {
    jQuery(document).trigger("close.facebox");
  };

  self.submitSurvey = function () {
    var params = self.surveyInformation();
    new Analytics().track("users", "intention_survey", params);
  };

  self.surveyInformation = function () {
    var info = {};
    info.intention_response = jQuery("#intention_response").val();
    info.contest_email = jQuery("#intention_email").val();
    info.page = window.location.href;
    return info;
  };
}
