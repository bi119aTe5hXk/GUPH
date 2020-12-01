# GUPH
Get user post hashtag from instagram

# How to use

1. Login to your instagram in browser and get sessionid & csrftoken from cookies.
2. Paste sessionid & csrftoken to app and don't forget to press the Apply button.
3. If you want to load the content for more than 12 posts, go to target user page and load few more page, then get query_hash form browser DevTools (in ?query_hash= request) and paste in Query Hash field.
4. Input username & press load button, it will load post data at 1sec per post. App will stop working until loading compete. 60 post will take more than 1min.
5. When it said "Load all post data competed", you can press Export button to export the tag list as csv file.

# CSV encoding
By default it's UTF-8, if mojibake shows up, open a new excel file and import as plain text file, then selct encoding as UTF-8.
