#include <CoreFoundation/CoreFoundation.h>
#include <Security/Authorization.h>
#include <Security/AuthorizationTags.h>


// Modified Apple code
// Changed to allow dynamic commands i.e.
// ./ScriptHelper /path/to/somecommand -p a -s s -a r -g -u m -e n -t s

int read (long,StringPtr,int);
int write (long,StringPtr,int);

int main (int argc, const char * argv[]) {
	
    OSStatus myStatus;
    AuthorizationFlags myFlags = kAuthorizationFlagDefaults;              // 1
    AuthorizationRef myAuthorizationRef;                                  // 2
	
    myStatus = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment,  // 3
								   myFlags, &myAuthorizationRef);
    if (myStatus != errAuthorizationSuccess)
        return myStatus;
	
    do
    {
        {
            AuthorizationItem myItems = {kAuthorizationRightExecute, 0,    // 4
				NULL, 0};
            AuthorizationRights myRights = {1, &myItems};                  // 5
			
            myFlags = kAuthorizationFlagDefaults |                         // 6
			kAuthorizationFlagInteractionAllowed |
			kAuthorizationFlagPreAuthorize |
			kAuthorizationFlagExtendRights;
            myStatus = AuthorizationCopyRights (myAuthorizationRef,       // 7
												&myRights, NULL, myFlags, NULL );
        }
		
        if (myStatus != errAuthorizationSuccess) break;
		
        {
			// Grab the arguent length
			int size = strlen(argv[1]);
			
			// Grab the first argument
			char myToolPath[size];
			strcpy(myToolPath,argv[1]);
			char **myArguments = (char **)&argv[2];
			
            FILE *myCommunicationsPipe = NULL;
            char myReadBuffer[128];
			
            myFlags = kAuthorizationFlagDefaults;                          // 8
            myStatus = AuthorizationExecuteWithPrivileges                  // 9
			(myAuthorizationRef, myToolPath, myFlags, myArguments,
			 &myCommunicationsPipe);
			// Any compile warnings here come from the sample apple code.
            if (myStatus == errAuthorizationSuccess)
                for(;;)
                {
                    int bytesRead = read (fileno (myCommunicationsPipe),
										  myReadBuffer, sizeof (myReadBuffer));
                    if (bytesRead < 1) break;
					write (fileno (stdout), myReadBuffer, bytesRead);
                }
        }
    } while (0);
	
    AuthorizationFree (myAuthorizationRef, kAuthorizationFlagDefaults);    // 10
	
    if (myStatus) printf("Status: %ld\n", myStatus);
    return myStatus;
}