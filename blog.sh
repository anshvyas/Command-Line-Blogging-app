#!/bin/bash

# Defining variables necessary for connection

DB_SERVER='localhost'
DB_USER='root'
DB_NAME='blog_app'


# function to list all the blogs

list_blogs()
{	
	#Establish connection and list all the blogs and store errors, if any 
	
	if mysql -h "$DB_SERVER" -u "$DB_USER" -p 2>> error.log <<EOF 
	USE ${DB_NAME};
	SELECT * FROM blogs;
	quit
EOF
	
	then
	return 0
	else
	return 1
	fi
}


# function to add a new blog

add_to_blog()
{
	#Check count of parameters and insert accordingly

	if [ "$#" -eq 2 ]
	then
        # to insert blog with title and content


	   local title="$1"
          local content="$2"
	   if mysql -u "$DB_SERVER" -u "$DB_USER" -p 2>> error.log <<EOF
           USE ${DB_NAME};
	   INSERT INTO blogs (title,content) VALUES ('${title}','${content}');
	   quit
EOF
	  then
	      return 0
          else
	      return 1
          fi

	elif [ "$#" -eq 3 ]
	then
	# to insert a blog with a title content and a category	

	   local title="$1"
           local content="$2"
           local category="$3"
       # function to check whether id exists
	   echo Checking category .....
           local ret_id=$(check_id $3)
	   echo Creating your blog....
	   if   mysql -h "$DB_SERVER" -u "$DB_USER" -p -e "
	        USE ${DB_NAME}; 
INSERT INTO blogs (title,content,category_id) VALUES ('${title}','${content}','${ret_id}');
		quit" 2>>error.log  
          then
	   return 0
	   else
           echo 1
	   fi  
	   


	fi

}

check_id(){
local cat=$1

#check whether id exists

local id=`mysql -h "$DB_SERVER" -u "$DB_USER" -p 2>>error.log -e "
          USE ${DB_NAME};
          SELECT cat_id from category WHERE cat_name='${cat}';
	  EXIT;"`

local res_array=( $(for i in $id; do echo $i; done) )

if [ -z ${res_array[1]} ]
then
echo 'Creating new category ....' >&2
# create the entry of id if doesn't exits
id=`mysql -h "$DB_SERVER" -u "$DB_USER" -p 2>>error.log -e "
    USE ${DB_NAME};
    INSERT INTO category (cat_name) VALUES ('${cat}');
    SELECT LAST_INSERT_ID();
    EXIT;
    "`
local arr=( $(for i in $id; do echo $i;done))

echo "${arr[1]}"
else
echo ${res_array[1]}
fi
}

if [ "$#" -ge 1 ]
then
case "$1" in 

  post)
	shift
# for viewing all the posts

   if [ "$#" -eq 1 -a "$1" = "list" ]
   then
    	 if list_blogs 
        then
	    echo "`date -R` : Blog List Displayed Successfully" >> server.log 
        else
	    echo 'Blog listing failed.See error.log for details'
	    echo "`date -R` : Blog Listing Failed" >> error.log
        fi



   # for adding a new blog with title and content specified
   
	elif [ "$#" -eq 3 -a "$1" = "add" ]
        then
        title="$2"
        content="$3"
	if add_to_blog "$title" "$content"
	then
            echo "Blog added successfully!!"
	    echo "`date -R` : Blog with TITLE: $title and CONTENT: $content added successfully">>server.log
	else
             echo "Failed to add the blog.See error.log for details"
             echo "`date -R` : Unable to add the blog with TiTLE: $title and CONTENT: $content ">>error.log
	fi
     
   # for adding blog with a title content and a given category
	elif [ "$#" -eq 5 -a "$1" = "add" -a "$4" = "--category" ]
        then
	title="$2"
	content="$3"
	category="$5"
	category=${category,,}
      	if add_to_blog "$title" "$content" "$category"
	then
	echo "Blog with given category added successfully!!"
	echo "`date -R` : Blog with TITLE : $title , CONTENT : $content and CATEGORY : $category added successfully" >> server.log
	else
	echo "Failed to add the blog .See error.log for details"
	echo"`date -R` : Unable to add the blog with TITLE : $title , CONTENT : $content and CATEGORY : $category" >> error.log 
        fi

   fi 

;;
add)
	shift 
	;;
esac
fi


