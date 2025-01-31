package comments

import rego.v1

import data.utils
import data.organizations

# input: {
#     "scope": <"create@issue"|"view"|"list"|"update"|"delete"> or null,
#     "auth": {
#         "user": {
#             "id": <num>,
#             "privilege": <"admin"|"user"|"worker"> or null
#         },
#         "organization": {
#             "id": <num>,
#             "owner": {
#                 "id": <num>
#             },
#             "user": {
#                 "role": <"owner"|"maintainer"|"supervisor"|"worker"> or null
#             }
#         } or null,
#     },
#     "resource": {
#         "id": <num>,
#         "owner": { "id": <num> },
#         "project": {
#             "owner": { "id": <num> },
#             "assignee": { "id": <num> }
#         } or null,
#         "task": {
#             "owner": { "id": <num> },
#             "assignee": { "id": <num> }
#         },
#         "job": {
#             "assignee": { "id": <num> }
#         },
#         "issue": {
#             "owner": { "id": <num> },
#             "assignee": { "id": <num> }
#         },
#         "organization": { "id": <num> } or null
#     }
# }

is_comment_owner if {
    input.resource.owner.id == input.auth.user.id
}

is_issue_owner if {
    input.resource.issue.owner.id == input.auth.user.id
}

is_issue_assignee if {
    input.resource.issue.assignee.id == input.auth.user.id
}

is_job_assignee if {
    input.resource.job.assignee.id == input.auth.user.id
}

is_task_owner if {
    input.resource.task.owner.id == input.auth.user.id
}

is_task_assignee if {
    input.resource.task.assignee.id == input.auth.user.id
}

is_project_owner if {
    input.resource.project.owner.id == input.auth.user.id
}

is_project_assignee if {
    input.resource.project.assignee.id == input.auth.user.id
}

is_project_staff if {
    is_project_owner
}

is_project_staff if {
    is_project_assignee
}

is_task_staff if {
    is_project_staff
}

is_task_staff if {
    is_task_owner
}

is_task_staff if {
    is_task_assignee
}

is_job_staff if {
    is_task_staff
}

is_job_staff if {
    is_job_assignee
}

is_issue_staff if {
    is_job_staff
}

is_issue_staff if {
    is_issue_owner
}

is_issue_staff if {
    is_issue_assignee
}

is_comment_staff if {
    is_issue_staff
}

is_comment_staff if {
    is_comment_owner
}

default allow := false

allow if {
    utils.is_admin
}

allow if {
    input.scope == utils.CREATE_IN_ISSUE
    utils.is_sandbox
    utils.has_perm(utils.WORKER)
    is_issue_staff
}

allow if {
    input.scope == utils.CREATE_IN_ISSUE
    input.auth.organization.id == input.resource.organization.id
    utils.is_organization
    utils.has_perm(utils.USER)
    organizations.has_perm(organizations.MAINTAINER)
}

allow if {
    input.scope == utils.CREATE_IN_ISSUE
    input.auth.organization.id == input.resource.organization.id
    utils.is_organization
    utils.has_perm(utils.WORKER)
    organizations.is_member
    is_issue_staff
}

allow if {
    input.scope == utils.LIST
    utils.is_sandbox
}

allow if {
    input.scope == utils.LIST
    organizations.is_member
}

filter := [] if { # Django Q object to filter list of entries
    utils.is_admin
    utils.is_sandbox
} else := qobject if {
    utils.is_admin
    utils.is_organization
    org := input.auth.organization
    qobject := [
        {"issue__job__segment__task__organization": org.id},
        {"issue__job__segment__task__project__organization": org.id}, "|"
    ]
} else := qobject if {
    utils.is_sandbox
    user := input.auth.user
    qobject := [
        {"owner": user.id},
        {"issue__owner": user.id}, "|",
        {"issue__assignee": user.id}, "|",
        {"issue__job__assignee": user.id}, "|",
        {"issue__job__segment__task__owner": user.id}, "|",
        {"issue__job__segment__task__assignee": user.id}, "|",
        {"issue__job__segment__task__project__owner": user.id}, "|",
        {"issue__job__segment__task__project__assignee": user.id}, "|"
    ]
} else := qobject if {
    utils.is_organization
    utils.has_perm(utils.USER)
    organizations.has_perm(organizations.MAINTAINER)
    org := input.auth.organization
    qobject := [
        {"issue__job__segment__task__organization": org.id},
        {"issue__job__segment__task__project__organization": org.id}, "|"
    ]
} else := qobject if {
    organizations.has_perm(organizations.WORKER)
    user := input.auth.user
    org := input.auth.organization
    qobject := [
        {"owner": user.id},
        {"issue__owner": user.id}, "|",
        {"issue__assignee": user.id}, "|",
        {"issue__job__assignee": user.id}, "|",
        {"issue__job__segment__task__owner": user.id}, "|",
        {"issue__job__segment__task__assignee": user.id}, "|",
        {"issue__job__segment__task__project__owner": user.id}, "|",
        {"issue__job__segment__task__project__assignee": user.id}, "|",
        {"issue__job__segment__task__organization": org.id},
        {"issue__job__segment__task__project__organization": org.id}, "|", "&"
    ]
}

allow if {
    input.scope == utils.VIEW
    utils.is_sandbox
    is_comment_staff
}

allow if {
    input.scope == utils.VIEW
    input.auth.organization.id == input.resource.organization.id
    utils.has_perm(utils.USER)
    organizations.has_perm(organizations.MAINTAINER)
}

allow if {
    input.scope == utils.VIEW
    input.auth.organization.id == input.resource.organization.id
    organizations.is_member
    is_comment_staff
}

allow if {
    input.scope in {utils.UPDATE, utils.DELETE}
    utils.is_sandbox
    utils.has_perm(utils.WORKER)
    is_comment_staff
}

allow if {
    input.scope in {utils.UPDATE, utils.DELETE}
    input.auth.organization.id == input.resource.organization.id
    utils.has_perm(utils.USER)
    organizations.has_perm(organizations.MAINTAINER)
}

allow if {
    input.scope in {utils.UPDATE, utils.DELETE}
    input.auth.organization.id == input.resource.organization.id
    is_comment_staff
    utils.has_perm(utils.WORKER)
    organizations.is_member
}
