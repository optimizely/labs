import os

import labs_constants

import contentful_management

def delete_lab(slug):
  '''
  Deletes a lab specified by the slug parameter

  Args:
    slug: string specifying the slug of the lab
  '''
  print('DELETING A SPECIFIC LAB')
  client = contentful_management.Client(labs_constants.CONTENTFUL_MANAGEMENT_TOKEN)
  entry = None
  try:
    print('Finding the lab %s...' % slug)
    entry = client.entries(labs_constants.CONTENTFUL_SPACE_ID, labs_constants.CONTENTFUL_ENVIRONMENT).find(slug)
  except contentful_management.errors.NotFoundError:
    print('Entry not found for slug %s, STOPPING delete step')
    return
  else:
    print('Found existing entry for slug %s, deleting...' % slug)
    
    if entry.is_published:
      entry.unpublish()
     
    entry.delete()

  print('FINISHED delete for slug %s' % slug)


def main():
  SLUG_TO_DELETE = os.environ['SLUG_TO_DELETE']
  delete_lab(SLUG_TO_DELETE)


main()
