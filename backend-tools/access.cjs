// Trusted local administration only. Credentials are supplied by the SDK's
// Application Default Credentials mechanism, never embedded or printed.
const {initializeApp,applicationDefault}=require('firebase-admin/app');
const {getAuth}=require('firebase-admin/auth');
const args=process.argv.slice(2);
const value=k=>args[args.indexOf(k)+1];
const uid=args.includes('--uid')?value('--uid'):null;
const role=args.includes('--role')?value('--role'):null;
if(!uid||!['admin','staff','revoke'].includes(role)){console.error('Usage: node access.cjs --uid USER_UID --role admin|staff|revoke');process.exit(1);}
initializeApp({credential:applicationDefault()});
(async()=>{const auth=getAuth(),user=await auth.getUser(uid),claims={...user.customClaims};delete claims.admin;delete claims.staff;if(role==='admin')claims.admin=true;if(role==='staff')claims.staff=true;await auth.setCustomUserClaims(uid,claims);if(role==='revoke')await auth.revokeRefreshTokens(uid);console.log('Application access updated. Sign out and back in to refresh claims.');})().catch(()=>{console.error('Access update failed. Check the target project, IAM permissions and UID. No credentials were printed.');process.exit(1);});
