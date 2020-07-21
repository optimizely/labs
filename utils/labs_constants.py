LABS_PATH = 'labs'
ARTIFACTS_PATH = 'artifacts'

# This satisfies the Contentful Entry Id requirements AND
# Enforces dashcase-ing which is what our Marketing slugs are
SLUG_REGEX_REQUIREMENT = '^[a-zA-Z0-9-.]{1,64}$'
CONTENTFUL_LAB_TYPE = 'lab'

CONTENTFUL_ENVIRONMENT = os.environ['LABS_CONTENTFUL_ENVIRONMENT']
CONTENTFUL_SPACE_ID = os.environ['LABS_CONTENTFUL_SPACE_ID']
CONTENTFUL_MANAGEMENT_TOKEN = os.environ['LABS_CONTENTFUL_MANAGEMENT_API_TOKEN']

LIBRARY_URL = os.environ['LIBRARY_URL']
LIBRARY_S3_BUCKET = os.environ['LIBRARY_S3_BUCKET']
LIBRARY_S3_ACCESS_KEY = os.environ.get('LIBRARY_S3_ACCESS_KEY')
LIBRARY_S3_SECRET_KEY = os.environ.get('LIBRARY_S3_SECRET_KEY')
