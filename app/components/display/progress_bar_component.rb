# frozen_string_literal: true

class Display::ProgressBarComponent < ViewComponent::Base

    def initialize(progress: '0')
        @progress = progress
    end
    def call
        content_tag(:div, class: 'progress-bar-component') {
            content_tag(:div, @progress+'%', class: 'progress-bar-component-text') +
            content_tag(:div, '', class: 'progress-bar-component-progress', style: 'width: '+@progress+'%;')
        }
    end
  end