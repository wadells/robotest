package ops

import (
	"encoding/json"
	"fmt"

	"time"

	. "github.com/onsi/gomega"
	web "github.com/sclevine/agouti"
)

type OpsProvider struct {
	page *web.Page
}

type SiteOperation struct {
	ID          string    `json:"id"`
	AccountID   string    `json:"account_id"`
	SiteDomain  string    `json:"site_domain"`
	Type        string    `json:"type"`
	Created     time.Time `json:"created"`
	Updated     time.Time `json:"updated"`
	State       string    `json:"state"`
	Provisioner string    `json:"provisioner"`
}

func CreateOpsProvider(page *web.Page) OpsProvider {
	return OpsProvider{page: page}
}

func (o *OpsProvider) GetLastOperationByType(opType string) *SiteOperation {
	const scriptTemplate = `
        var opsMap = reactor.evaluate(["op"]);        
        filteredOps = opsMap.valueSeq().filter( i => i.get("type") === "%v" );

        if(filteredOps.count() > 0 ){        
            var last = filteredOps
                .sortBy( i => i.get("created") )
                .last()
                .toJS();

            return JSON.stringify(last);
        }
        
        return "";
    `

	var js = fmt.Sprintf(scriptTemplate, opType)
	var jsOutput string
	var lastOp SiteOperation

	Expect(o.page.RunScript(js, nil, &jsOutput)).ShouldNot(
		HaveOccurred(),
		"should filter operations by type using JS")

	if jsOutput == "" {
		return nil
	}

	Expect(json.Unmarshal([]byte(jsOutput), &lastOp)).To(
		Succeed(),
		"should unmarshal operation object")

	return &lastOp
}
