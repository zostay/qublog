(function($) {
    var setupHelp = function($help, options) {
        var contextsSelector = options.contexts || '.context';

        $help.data('contextsSelector', contextsSelector);
        $help.hide();
        $help.find(contextsSelector).hide();
    };

    var updateHelp = function($help, options) {
        var contextSelector = options.context;
        var $context = $('#' + contextSelector);

        // Already shown, stop
        if ($context.hasClass('visible-context')) return;

        var showNext = function() {
            $help.find($help.data('contextsSelector'))
                 .removeClass('visible-context')
                 .hide();

            if ($context.length) {
                $context.show()
                        .addClass('visible-context');
                $help.fadeIn('normal');
            }
        };

        var $visibleContext = $help.find('.visible-context');
        if ($visibleContext.length) {
            $help.fadeOut('normal', showNext);
        }
        else {
            showNext();
        }
    };

    $.fn.help = function(action, options) {
        if (!options) options = {};
        switch (action) {
            case 'init': case 'initialize': case 'setup':
                setupHelp(this, options);
                break;
            case 'update':
                updateHelp(this, options);
                break;
            case 'hide':
                updateHelp(this, { });
                break;
            default:
                throw "invalid help action " + action;
        }

        return this;
    };

    $.fn.helpContext = function(type, help, context) {
        var $help = $(help);

        if (context == 'clear') {
            this.bind(type, function() {
                $help.help('hide');
            });
        }

        else {
            this.bind(type, function() {
                $help.help('update', { context: context });
            });
        }

        return this;
    };
})(jQuery);
