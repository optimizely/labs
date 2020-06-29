import os
import json
import re
import shutil
import boto3
from botocore.exceptions import NoCredentialsError

import frontmatter
import contentful_management

LABS_PATH = 'labs'
ARTIFACTS_PATH = 'artifacts'
CONTENTFUL_LAB_TYPE = 'lab'
CONTENTFUL_ENVIRONMENT = os.environ['LABS_CONTENTFUL_ENVIRONMENT']
CONTENTFUL_SPACE_ID = os.environ['LABS_CONTENTFUL_SPACE_ID']
CONTENTFUL_MANAGEMENT_TOKEN = os.environ['LABS_CONTENTFUL_MANAGEMENT_API_TOKEN']
CONTENTFUL_ID_REGEX_REQUIREMENT = '^[a-zA-Z0-9-_.]{1,64}$'

LIBRARY_S3_BUCKET = 'library-optimizely-com'
LIBRARY_S3_ACCESS_KEY = os.environ.get('LIBRARY_S3_ACCESS_KEY')
LIBRARY_S3_SECRET_KEY = os.environ.get('LIBRARY_S3_SECRET_KEY')
LIBRARY_URL = 'https://library.optimizely.com/'


client = contentful_management.Client(CONTENTFUL_MANAGEMENT_TOKEN)

SLUG_BLACKLIST = []

def get_slugs():
  '''
  Gets the list of slugs, which are the directory names of
  each directory under the labs/ directory

  Returns:
    List of strings representing slugs
  '''
  slugs = []

  # r=root, d=directories, f = files
  for r, d, f in os.walk(LABS_PATH):
      slugs = [folder for folder in d]
      break

  return slugs

def get_info(slug):
  '''
  Retrieves the metadata for a specific lab

  Returns:
    Dictionary of the metadata from metadata.md under a particular lab
  '''
  frontmatter_object = frontmatter.load(os.path.join(LABS_PATH, slug, 'metadata.md'))
  return frontmatter_object.metadata

def get_markdown(slug):
  '''
  Retrieves the markdown text for the specific lab
  TODO: Use Jupyter notebook file as a priority?

  Returns:
    String representing the markdown from README.md under a particular lab
  '''
  f = open(os.path.join(LABS_PATH, slug, 'README.md'), 'r')
  return f.read()


def zip_contents(slug):
  print('Zipping contents for lab %s...' % slug)
  lab_path = os.path.join(LABS_PATH, slug)
  output_path = os.path.join(ARTIFACTS_PATH, slug, 'resources')

  shutil.make_archive(output_path, 'zip', lab_path)

  file_path = output_path + '.zip'
  size = os.path.getsize(file_path)
  print('Finished zipping contents. Size: %s bytes' % size)
  return file_path


def upload_to_aws(local_file_path, bucket, s3_file_path):
  '''
  Uploads an item to S3

  Args:
    local_file_path: Path to file to upload to S3
    bucket: Name of S3 bucket
    s3_file_path: Path to file on S3

  Returns:
    Boolean indicating whether the upload was successful
  '''
  s3 = boto3.client(
    's3',
    aws_access_key_id=LIBRARY_S3_ACCESS_KEY,
    aws_secret_access_key=LIBRARY_S3_SECRET_KEY
  )

  try:
    s3.upload_file(
      local_file_path,
      bucket,
      s3_file_path,
      {'ACL': 'public-read'}
    )
    print('Upload successful to %s' % s3_file_path)
    return True
  except FileNotFoundError:
    print('File %s was not found for bucket %s' % (s3_file_path, bucket))
    print('AWS zip upload failed')
    return False
  except NoCredentialsError:
    print('AWS credentials not available')
    print('AWS zip upload failed')
    return False


def publish_lab(slug):
  '''
  Zips the contents of the lab and uploads the zip file to S3.

  Args:
    slug: String representing the slug of the lab
  '''
  zip_path = zip_contents(slug)
  s3_path = os.path.join(LABS_PATH, ARTIFACTS_PATH, slug, 'resources.zip')
  uploaded = upload_to_aws(zip_path, LIBRARY_S3_BUCKET, s3_path)

  lab_info = get_info(slug)
  lab_info['markdown'] = get_markdown(slug)

  resource_url = LIBRARY_URL + s3_path
  lab_info['resourceUrl'] = resource_url if uploaded else None

  upsert_lab_to_contentful(slug, lab_info)


def upsert_lab_to_contentful(slug, lab_info):
  '''
  Update or insert a lab based on the slug. If a slug already exists as an
  entry in contentful, update that item. Otherwise, insert a new item
  for that slug representing a new lab.

  Arguments:
    slug: String representing the slug of the lab
    lab_info: Dictionary representing the information about the lab
  '''
  entry_attributes = {
    'content_type_id': CONTENTFUL_LAB_TYPE,
    'fields': {
      'slug': {
        'en-US': slug,
      },
      'title': {
        'en-US': lab_info['title'],
      },
      'summary': {
        'en-US': lab_info['summary'],
      },
      'body': {
        'en-US': lab_info['markdown'],
      },
      'resourceUrl': {
        'en-US': lab_info['resourceUrl']
      },
      'revisionDate': {
        'en-US': lab_info['revisionDate'],
      },
      'labels': {
        'en-US': lab_info['labels'],
      },
      'author': {
        'en-US': lab_info['author'],
      },
      'seo': {
        'en-US': lab_info['seo'],
      },
    }
  }

  print('*** SLUG: %s' % slug)
  entry = None

  try:
    entry = client.entries(CONTENTFUL_SPACE_ID, CONTENTFUL_ENVIRONMENT).find(slug)
  except contentful_management.errors.NotFoundError:
    print('Entry not found for slug %s, creating a new one...' % slug)
    entry = client.entries(CONTENTFUL_SPACE_ID, CONTENTFUL_ENVIRONMENT).create(
      slug,
      entry_attributes
    )
  else:
    print('Found existing entry for slug %s, updating...' % slug)
    entry.update(entry_attributes)
    entry.save()

  entry.publish()
  print('Finished upsert for slug %s' % slug)


def main():
  print('======= Step 0 =======')
  print('Filtering labs that should not be published based on hard coded blacklist:')
  for slug in SLUG_BLACKLIST:
    print(slug)

  slugs = [slug for slug in get_slugs() if slug not in SLUG_BLACKLIST]

  print('======= Step 1 =======')
  print('Enumerated the following labs:')
  for slug in slugs:
    print(slug)


  print('======= Step 2 =======')
  print('Asserting slugs are in proper format...')
  for slug in slugs:
    try:
      assert re.match(CONTENTFUL_ID_REGEX_REQUIREMENT, slug)
    except:
      print('Error! Slug must be alphanumeric, dashes, underscores, and periods, between 1 and 64 characters. Got: %s' % slug)
  print('All slugs satisfy string requirements!')

  print('======= Step 3 =======')
  print('Updating labs...')
  for slug in slugs:
    try:
      publish_lab(slug)
    except Exception as error:
      print('ERROR publishing %s...' % slug)
      print(error)
  print('Finished publishing step!')

main()
