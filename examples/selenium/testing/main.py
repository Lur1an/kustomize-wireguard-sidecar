from selenium import webdriver
from time import sleep

from selenium.webdriver.common import desired_capabilities

driver = webdriver.Remote(
    command_executor='http://localhost:4444',
    options=webdriver.ChromeOptions()
)
driver.get("https://whatismyipaddress.com/")
sleep(30)
driver.quit()
