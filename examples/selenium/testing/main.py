from selenium import webdriver
from time import sleep

from selenium.webdriver.common import desired_capabilities

driver = webdriver.Remote(
    command_executor='http://localhost:4444',
    options=webdriver.ChromeOptions()
)
sleep(10)
driver.quit()
