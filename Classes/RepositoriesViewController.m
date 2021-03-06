#import "RepositoriesViewController.h"
#import "RepositoryViewController.h"
#import "GHUser.h"
#import "GHRepository.h"
#import "GHReposParserDelegate.h"


@implementation RepositoriesViewController

@synthesize privateRepositories, publicRepositories;

- (void)viewDidLoad {
    [super viewDidLoad];
	isLoaded = NO;
	self.title = @"My Repositories";
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:activityView] autorelease];
	[self performSelectorInBackground:@selector(parseXML) withObject:nil];
}

- (void)parseXML {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	// Load settings
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *username = [defaults stringForKey:kUsernameDefaultsKey];
	NSString *token = [defaults stringForKey:kTokenDefaultsKey];
	NSString *url = [NSString stringWithFormat:kUserReposFormat, username, token];
	NSURL *reposURL = [NSURL URLWithString:url];
	GHReposParserDelegate *parserDelegate = [[GHReposParserDelegate alloc] initWithTarget:self andSelector:@selector(loadedRepositories:)];
	NSXMLParser *parser = [[NSXMLParser alloc] initWithContentsOfURL:reposURL];
	[parser setDelegate:parserDelegate];
	[parser setShouldProcessNamespaces:NO];
	[parser setShouldReportNamespacePrefixes:NO];
	[parser setShouldResolveExternalEntities:NO];
	[parser parse];
	[parser release];
	[parserDelegate release];
	[pool release];
}

- (void)loadedRepositories:(id)theResult {
	if ([theResult isKindOfClass:[NSError class]]) {
		// Let's just assume it's an authentication error
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Authentication error" message:@"Please revise the settings and check your username and API token" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		[alert release];
	} else {
		self.privateRepositories = [NSMutableArray array];
		self.publicRepositories = [NSMutableArray array];
		for (GHRepository *repo in theResult) {
			(repo.isPrivate) ? [privateRepositories addObject:repo] : [publicRepositories addObject:repo];
		}
	}
	isLoaded = YES;
	[self.tableView reloadData];
}

#pragma mark -
#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return (isLoaded) ? 2 : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (!isLoaded) return 1;
	NSArray *repos = (section == 0) ? privateRepositories : publicRepositories;
	return (repos.count == 0) ? 1 : repos.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (!isLoaded) return @"";
	return (section == 0) ? @"Private" : @"Public";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (!isLoaded) return loadingReposCell;
	NSArray *repos = (indexPath.section == 0) ? privateRepositories : publicRepositories;
	if (indexPath.section == 0 && repos.count == 0) return noPrivateReposCell;
	if (indexPath.section == 1 && repos.count == 0) return noPublicReposCell;
	if (indexPath.section == 1) {
		GHRepository *repository = [repos objectAtIndex:indexPath.row];
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kRepositoryCellIdentifier];
		if (cell == nil) cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:kRepositoryCellIdentifier] autorelease];
		cell.font = [UIFont systemFontOfSize:16.0f];
		cell.text = repository.name;
		cell.image = [UIImage imageNamed:(repository.isPrivate ? @"private.png" : @"public.png")];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		return cell;
	}
	return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSArray *repos = (indexPath.section == 0) ? privateRepositories : publicRepositories;
	GHRepository *repo = [repos objectAtIndex:indexPath.row];
	RepositoryViewController *repoController = [[RepositoryViewController alloc] initWithRepository:repo];
	[self.navigationController pushViewController:repoController animated:YES];
	[repoController release];
}

#pragma mark -
#pragma mark Cleanup

- (void)dealloc {
	[activityView release];
	[noPublicReposCell release];
	[noPrivateReposCell release];
	[publicRepositories release];
	[privateRepositories release];
    [super dealloc];
}

@end

