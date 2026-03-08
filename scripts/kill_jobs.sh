for id in $(gh run list --limit 5000 --jq ".[] | select (.status == \"queued\" or .status == \"in_progress\") | .databaseId" --json databaseId,status); do
  gh run cancel $id
done