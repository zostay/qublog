if (!window.Qublog)  window.Qublog  = {};
if (!Qublog.Project) Qublog.Project = {};

Qublog.Project.drop = function(e, ui) {
    var dropPoint = jQuery(this);
    if (dropPoint.hasClass('subject')) {
        dropPoint = dropPoint.parent('.task');
    }

    var taskParent = dropPoint;
    var taskChild  = ui.draggable;

    var parentId = taskParent.attr('id').substr(5);
    var childId  = taskChild.attr('id').substr(5);

    var parentRegion = taskParent.parents('.jifty-region').get(0).id.substr(7);
    var childRegion  = taskChild.parents('.jifty-region').get(0).id.substr(7);

    var params = {
        actions: {},
        action_arguments: {}
    };
    params.action_arguments['update-task-' + childId] = {};
    params.action_arguments['update-task-' + childId]['parent'] = parentId
    params.actions['update-task-' + childId] = 1;
    params.fragments = [
        {
            mode: 'Replace',
            region: parentRegion + '-children_of_' + parentId,
            path: 'project/list_tasks'
        },
        {
            mode: 'Replace',
            region: childRegion,
            path: 'project/list_tasks'
        },
        {
            mode: 'Replace',
            region: 'task_list-list_tasks',
            path: 'project/list_tasks'
        }
    ];

    Jifty.update(params, this);

    return true;
};

Behaviour.register({
    '.task': function(e) {
        // none project is not draggable
        if (!jQuery(e).hasClass('none-project')) {
            jQuery(e).draggable({
                handle: '.subject',
                helper: 'original',
                revert: true
            });
        }
    },

    '.task > .subject': function(e) {
        jQuery(e).droppable({
            accept: '.task',
            activeClass: 'dropbox',
            hoverClass: 'hoverbox',
            drop: Qublog.Project.drop
        });
    },

    '.top_level': function(e) {
        jQuery(e).droppable({
            accept: '.action, .group',
            activeClass: 'dropbox',
            hoverClass: 'hoverbox',
            drop: Qublog.Project.drop
        });
    }, 

    '.task .subject': function(e) {
        var subject = jQuery(e);

        // none project is not editable
        if (subject.parent().hasClass('none-project')) return;

        var taskId  = subject.parent().attr("id").substr(5);
        var checked;
        if (subject.parent().hasClass('done')) {
            checked = "checked";
        }

        subject.prepend(
            '<input type="checkbox" id="task-checkbox-' + taskId + '"'
                + ' class="complete-box" ' + checked + '/>'
        );
        jQuery("#task-checkbox-" + taskId).click(function() {
            var actions = {};
            actions['update-task-' + taskId] = 1;

            var action_arguments = {};
            action_arguments['update-task-' + taskId] = {
                'status': this.checked ? 'done' : 'open'
            };

            return Jifty.update({
                'continuation': {},
                'actions': actions,
                'fragments': [
                    {
                        'mode': 'Replace',
                        'args': {},
                        'region': 'task_list-list_tasks',
                        'path': 'project/list_tasks'
                    }
                ],
                'action_arguments': action_arguments
            }, this);
        });
    },
});
