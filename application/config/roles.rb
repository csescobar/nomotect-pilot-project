ApplicationRoles.register :administrator, permissions: %w[service_requests.create service_requests.read service_requests.manage service_requests.assign service_requests.export]
ApplicationRoles.register :support_agent, permissions: %w[service_requests.read service_requests.assign service_requests.export]
ApplicationRoles.register :requester, permissions: %w[service_requests.create service_requests.read_own]
