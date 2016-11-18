package ui

import (
	"regexp"
	"time"

	log "github.com/Sirupsen/logrus"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"github.com/sclevine/agouti"
	. "github.com/sclevine/agouti/matchers"
)

const (
	WithEmail  = "withEmail"
	WithGoogle = "google"
)

type User struct {
	page     *agouti.Page
	email    string
	password string
}

func EnsureUser(page *agouti.Page, URL string, username string, password string, authType string) {
	Expect(page.Navigate(URL)).To(Succeed())
	count, _ := page.FindByClass("grv-user-login").Count()

	if count != 0 {
		user := CreateUser(page, username, password)
		switch authType {
		case WithEmail:
			user.LoginWithEmail()
		case WithGoogle:
			user.LoginWithGoogle()
		default:
			Fail("Unknown auth type")
		}

		time.Sleep(1 * time.Second)
	}
}

func CreateUser(page *agouti.Page, email string, password string) *User {
	return &User{page: page, email: email, password: password}
}

func (u *User) NavigateToLogin() {
	r, _ := regexp.Compile("/web/.*")
	url, _ := u.page.URL()
	url = r.ReplaceAllString(url, "/web/login")

	Expect(u.page.Navigate(url)).To(Succeed())
	Eventually(u.page.FindByClass("grv-user-login"), defaultTimeout).Should(BeFound())
}

func (u *User) LoginWithEmail() {
	page := u.page
	Expect(page.FindByName("email").Fill(u.email)).To(Succeed())
	Expect(page.FindByName("password").Fill(u.password)).To(Succeed())
	Expect(page.FindByClass("btn-primary").Click()).To(Succeed())
	Eventually(page.URL, defaultTimeout).ShouldNot(HaveSuffix("/login"))
}

func (u *User) LoginWithGoogle() {
	page := u.page
	Expect(page.FindByClass("btn-google").Click()).To(Succeed())
	Expect(page.FindByID("Email").Fill(u.email)).To(Succeed())
	Expect(page.FindByID("next").Click()).To(Succeed())
	Eventually(page.FindByID("Passwd"), defaultTimeout).Should(BeFound())

	time.Sleep(1 * time.Second)

	Expect(page.FindByID("Passwd").Fill(u.password)).To(Succeed())
	Expect(page.FindByID("signIn").Click()).To(Succeed())

	time.Sleep(1 * time.Second)

	allowBtn := page.FindByID("submit_approve_access")

	count, _ := allowBtn.Count()

	if count > 0 {
		Expect(allowBtn.Click()).To(Succeed())
	}

}

func (u *User) Signout() {
	page := u.page
	Eventually(page.FindByClass("fa-sign-out"), defaultTimeout).Should(BeFound())
	Expect(page.FindByClass("fa-sign-out").Click()).To(Succeed())
	Eventually(page.FindByClass("grv-user-login")).Should(BeFound())
}
