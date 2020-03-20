COMPONENT=HomeChallenge1AppC
include $(MAKERULES)
git:
	git add .
	git commit -m "$m"
	git push -u origin master 
