# Words Counter

Words Counter API allow you to analyze source text and keep track of how many times a word appeared in all texts analyzed.

Ruby version - 2.7
Rails version - 6.0

The API has 2 endpoints:
#### POST /analyze-text
The endpoint expects a json with 2 fields: source and source_type.

There are 3 acceptable source types values: string, file_path or url.

Depending on the value of the source_type the service will expect a different source value.

- string - the source must be a string no longer than 1000 characters
- file_path - the source must be a valid path to a file existing in the host running the service, the path must be relative to the service's working directory
- url - the source must be a valid URL to a text file.

#### GET /words/:word
The endpoint accepts a word and returns the amount of times the word was present in texts analyzed so far.

### System dependencies
The service uses SQLite for storing word counts
The SQLite DB is also used by the Delayed::Job gem

#### Database creation
Run `rails db:migrate` to create the necessary tables.
Make sure you have a Redis server running with the default host and port localhost:6379 

### Deployment instructions
To deploy the web server open the terminal and run: `rails s` 

To start the jobs manager run: `QUEUES=string,file_path,url rake jobs:work`

## Services (job queues, cache servers, search engines, etc.)
I used a rails controller for the /analyze-text endpoint, there were 2 main things I had to take into account:

1. The endpoint must have a low response time, the actual analysis of the text must not happen as part of processing the request.
2. Since the text files can be very large I need to make sure I do not load them to memory but use a different solution.

In order to solve issue #1 I decided to use a jobs manager package called Delayed::Job, it uses the DB for its queues and 
is very simple to use and set up, using the DB for queueing does limit the scale but it is ok for the current load ;)

I took the liberty to assume that the string type of input is bounded, I think this is a reasonable assumption cause a 
production grade API will prefer the client to upload the text file to a specialized storage and not to the host.
I set the string limit at 1000 characters but it can be set to a higher number.

I didn't set a limit in the rails server on the payload size, the default server coming with Rails is Puma, 
and I researched how to do it but I don't think it is critical for this exercise.

A request coming in will create a job to be processed later and the client will immediately get a 202 response or an 
error message in case of an invalid input. 

I created 2 job classes, one for string input and one for file or URL input, the string is simple cause it is relatively small, 
just count the words and bulk insert the results in batches, the file and URL input are more complicated because of their size.

In order to count the words I created a class that uses a gem called 'Pragmatic tokenizer' in order to tokenize the text 
and I used a Redis hash to store the transient job data, the reason I didn't use a Ruby hash is because for a large text 
file it could potentially consume a lot of memory. The TextAnalyzer class and the RedisFrequencyStore are located in the 
/lib directory, it is a Rails convention that the /lib directory is where you put classes/modules that can be extracted 
to be gems.

Using a Redis Hash created a challenge when it came to persisting the data once the processing was done, since Redis 
hash iterator does not guarantee to return each field once I had to make sure I do not count duplicate, 
on top of that I did want to create an INSERT query for each word but to INSERT in batches so I had to implement my own 
batch upsert SQLilte query in the 'Word' model and not use ActiveRecord for the inserts/updates.

To read the local files and external files I used the OpenURI class that supports both with the same syntax, 
for local files it iterates on the lines one by one and for URLs it download the file to a temporary local file and 
then does the same thing, it is not the quickest solution, I can probably optimize it to read a batch of lines at once 
instead of one but I cared less about the processing time and more about memory (and my time) in this exercise.

The validation of the input and the decision of which job to create is done in the TextProcessorService which is called
from the controller, I try to keep the controller as lean as possible.

## usage examples

### /analyze-text
String source type

```
curl -X POST \
  http://localhost:3000/analyze-text \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -d '{
"source_type": "string", "source": "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry'\''s standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum."
}'
```

File path source type
```
curl -X POST \
  http://localhost:3000/analyze-text \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -d '{
"source_type": "file_path", "source": "tmp/text_file.txt"
}'
```

URL source type
```
curl -X POST \
  http://localhost:3000/analyze-text \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -d '{
"source_type": "url", "source": "https://norvig.com/big.txt"
}'
```

### /words/:word

```
curl -X GET \
  http://localhost:3000/words/lorem \
  -H 'cache-control: no-cache' 
```