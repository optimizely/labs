import labs_constants

SLUG_TO_DELETE = os.environ['SLUG_TO_DELETE']

def main():
  print('DELETING A SPECIFIC LAB')

  print('======= Step 0 =======')
  print('Find the lab ')
  client = contentful_management.Client(labs_constants.CONTENTFUL_MANAGEMENT_TOKEN)
  entry = client.entries(labs_constants.CONTENTFUL_SPACE_ID, labs_constants.CONTENTFUL_ENVIRONMENT).find(slug)
  except contentful_management.errors.NotFoundError:
    print('Entry not found for slug %s, done with delete step')
    return
  else:
    print('Found existing entry for slug %s, deleting...' % slug)
    entry.unpublish()
    entry.delete()

  print('Finished DELETE for slug %s' % slug)

main()
