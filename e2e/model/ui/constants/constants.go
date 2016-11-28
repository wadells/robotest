package constants

import "time"

const (
	// FindTimeout defines the timeout to use for lookup operations
	FindTimeout = 20 * time.Second

	// SelectionPollInterval specifies the frequency of polling for elements
	SelectionPollInterval = 2 * time.Second

	// AgentTimeout defines the amount of time to wait for agents to connect
	AgentServerTimeout = 5 * time.Minute

	// InstallTimeout defines the amount of time to wait for installation to complete
	InstallTimeout = 20 * time.Minute

	// PollInterval defines the frequency of polling attempts
	PollInterval = 10 * time.Second

	PauseTimeout = 100 * time.Millisecond

	AjaxCallTimeout   = 20 * time.Second
	ServerLoadTimeout = 20 * time.Second
	ElementTimeout    = 20 * time.Second

	// Waiting time for operation to be completed (Expand and Application Update operations)
	OperationTimeout = 10 * time.Minute

	// InitializeTimeout is the amount of time between expand/shrink tests
	InitializeTimeout = 20 * time.Second
)
