**THIS CHECKLIST IS NOT COMPLETE**. Use `--show-ignored-findings` to show all the results.
Summary
 - [timestamp](#timestamp) (5 results) (Low)
 - [costly-loop](#costly-loop) (5 results) (Informational)
 - [cyclomatic-complexity](#cyclomatic-complexity) (1 results) (Informational)
 - [solc-version](#solc-version) (1 results) (Informational)
 - [naming-convention](#naming-convention) (13 results) (Informational)
 - [immutable-states](#immutable-states) (1 results) (Optimization)
## timestamp
Impact: Low
Confidence: Medium
 - [ ] ID-0
[SenatePositions.isCaesar(address)](contracts/ERC721/SenatePositions.sol#L493-L509) uses timestamp for comparisons
	Dangerous comparisons:
	- [activeCaesar[i] == _address && block.timestamp < caesars[ownedTokenId].endTime](contracts/ERC721/SenatePositions.sol#L503)

contracts/ERC721/SenatePositions.sol#L493-L509


 - [ ] ID-1
[SenatePositions.isTribune(address)](contracts/ERC721/SenatePositions.sol#L470-L486) uses timestamp for comparisons
	Dangerous comparisons:
	- [activeTribunes[i] == _address && block.timestamp < tribunes[ownedTokenId].endTime](contracts/ERC721/SenatePositions.sol#L480)

contracts/ERC721/SenatePositions.sol#L470-L486


 - [ ] ID-2
[SenatePositions.isConsul(address)](contracts/ERC721/SenatePositions.sol#L399-L417) uses timestamp for comparisons
	Dangerous comparisons:
	- [activeConsuls[i] == _address && block.timestamp < consuls[ownedTokenId].endTime](contracts/ERC721/SenatePositions.sol#L411)

contracts/ERC721/SenatePositions.sol#L399-L417


 - [ ] ID-3
[SenatePositions.isSenator(address)](contracts/ERC721/SenatePositions.sol#L424-L440) uses timestamp for comparisons
	Dangerous comparisons:
	- [activeSenators[i] == _address && block.timestamp < senators[ownedTokenId].endTime](contracts/ERC721/SenatePositions.sol#L434)

contracts/ERC721/SenatePositions.sol#L424-L440


 - [ ] ID-4
[SenatePositions.isCensor(address)](contracts/ERC721/SenatePositions.sol#L447-L463) uses timestamp for comparisons
	Dangerous comparisons:
	- [activeCensors[i] == _address && block.timestamp < censors[ownedTokenId].endTime](contracts/ERC721/SenatePositions.sol#L457)

contracts/ERC721/SenatePositions.sol#L447-L463


## costly-loop
Impact: Informational
Confidence: Medium
 - [ ] ID-5
[SenatePositions.burn(uint256)](contracts/ERC721/SenatePositions.sol#L234-L305) has costly operations inside a loop:
	- [activeConsuls = temp](contracts/ERC721/SenatePositions.sol#L245)

contracts/ERC721/SenatePositions.sol#L234-L305


 - [ ] ID-6
[SenatePositions.burn(uint256)](contracts/ERC721/SenatePositions.sol#L234-L305) has costly operations inside a loop:
	- [activeTribunes.pop()](contracts/ERC721/SenatePositions.sol#L269)

contracts/ERC721/SenatePositions.sol#L234-L305


 - [ ] ID-7
[SenatePositions.burn(uint256)](contracts/ERC721/SenatePositions.sol#L234-L305) has costly operations inside a loop:
	- [activeSenators.pop()](contracts/ERC721/SenatePositions.sol#L281)

contracts/ERC721/SenatePositions.sol#L234-L305


 - [ ] ID-8
[SenatePositions.burn(uint256)](contracts/ERC721/SenatePositions.sol#L234-L305) has costly operations inside a loop:
	- [activeCaesar.pop()](contracts/ERC721/SenatePositions.sol#L293)

contracts/ERC721/SenatePositions.sol#L234-L305


 - [ ] ID-9
[SenatePositions.burn(uint256)](contracts/ERC721/SenatePositions.sol#L234-L305) has costly operations inside a loop:
	- [activeCensors.pop()](contracts/ERC721/SenatePositions.sol#L257)

contracts/ERC721/SenatePositions.sol#L234-L305


## cyclomatic-complexity
Impact: Informational
Confidence: High
 - [ ] ID-10
[SenatePositions.burn(uint256)](contracts/ERC721/SenatePositions.sol#L234-L305) has a high cyclomatic complexity (16).

contracts/ERC721/SenatePositions.sol#L234-L305


## solc-version
Impact: Informational
Confidence: High
 - [ ] ID-11
solc-0.8.20 is not recommended for deployment

## naming-convention
Impact: Informational
Confidence: High
 - [ ] ID-12
Parameter [SenatePositions.isTribune(address)._address](contracts/ERC721/SenatePositions.sol#L470) is not in mixedCase

contracts/ERC721/SenatePositions.sol#L470


 - [ ] ID-13
Parameter [SenatePositions.isSenator(address)._address](contracts/ERC721/SenatePositions.sol#L424) is not in mixedCase

contracts/ERC721/SenatePositions.sol#L424


 - [ ] ID-14
Parameter [SenatePositions.updateTermLength(ISenatePositions.Position,uint256)._newTermLength](contracts/ERC721/SenatePositions.sol#L312) is not in mixedCase

contracts/ERC721/SenatePositions.sol#L312


 - [ ] ID-15
Parameter [SenatePositions.burn(uint256)._tokenId](contracts/ERC721/SenatePositions.sol#L234) is not in mixedCase

contracts/ERC721/SenatePositions.sol#L234


 - [ ] ID-16
Parameter [SenatePositions.updateSenateAddress(address)._updatedSenateAddress](contracts/ERC721/SenatePositions.sol#L342) is not in mixedCase

contracts/ERC721/SenatePositions.sol#L342


 - [ ] ID-17
Parameter [SenatePositions.getPosition(address)._address](contracts/ERC721/SenatePositions.sol#L378) is not in mixedCase

contracts/ERC721/SenatePositions.sol#L378


 - [ ] ID-18
Parameter [SenatePositions.updateTermLength(ISenatePositions.Position,uint256)._position](contracts/ERC721/SenatePositions.sol#L312) is not in mixedCase

contracts/ERC721/SenatePositions.sol#L312


 - [ ] ID-19
Parameter [SenatePositions.isConsul(address)._address](contracts/ERC721/SenatePositions.sol#L399) is not in mixedCase

contracts/ERC721/SenatePositions.sol#L399


 - [ ] ID-20
Parameter [SenatePositions.mint(ISenatePositions.Position,address)._position](contracts/ERC721/SenatePositions.sol#L178) is not in mixedCase

contracts/ERC721/SenatePositions.sol#L178


 - [ ] ID-21
Parameter [SenatePositions.mint(ISenatePositions.Position,address)._to](contracts/ERC721/SenatePositions.sol#L178) is not in mixedCase

contracts/ERC721/SenatePositions.sol#L178


 - [ ] ID-22
Parameter [SenatePositions.tokenURI(uint256)._tokenId](contracts/ERC721/SenatePositions.sol#L354) is not in mixedCase

contracts/ERC721/SenatePositions.sol#L354


 - [ ] ID-23
Parameter [SenatePositions.isCensor(address)._address](contracts/ERC721/SenatePositions.sol#L447) is not in mixedCase

contracts/ERC721/SenatePositions.sol#L447


 - [ ] ID-24
Parameter [SenatePositions.isCaesar(address)._address](contracts/ERC721/SenatePositions.sol#L493) is not in mixedCase

contracts/ERC721/SenatePositions.sol#L493


## immutable-states
Impact: Optimization
Confidence: High
 - [ ] ID-25
[SenatePositions.timelockContract](contracts/ERC721/SenatePositions.sol#L100) should be immutable 

contracts/ERC721/SenatePositions.sol#L100


**THIS CHECKLIST IS NOT COMPLETE**. Use `--show-ignored-findings` to show all the results.
Summary
 - [timestamp](#timestamp) (5 results) (Low)
 - [costly-loop](#costly-loop) (5 results) (Informational)
 - [cyclomatic-complexity](#cyclomatic-complexity) (1 results) (Informational)
 - [solc-version](#solc-version) (1 results) (Informational)
 - [naming-convention](#naming-convention) (13 results) (Informational)
 - [similar-names](#similar-names) (6 results) (Informational)
 - [immutable-states](#immutable-states) (1 results) (Optimization)
## timestamp
Impact: Low
Confidence: Medium
 - [ ] ID-0
[SenatePositions.isCensor(address)](contracts/ERC721/SenatePositions.sol#L455-L471) uses timestamp for comparisons
	Dangerous comparisons:
	- [activeCensors[i] == _address && block.timestamp < censors[ownedTokenId].endTime](contracts/ERC721/SenatePositions.sol#L465)

contracts/ERC721/SenatePositions.sol#L455-L471


 - [ ] ID-1
[SenatePositions.isTribune(address)](contracts/ERC721/SenatePositions.sol#L478-L494) uses timestamp for comparisons
	Dangerous comparisons:
	- [activeTribunes[i] == _address && block.timestamp < tribunes[ownedTokenId].endTime](contracts/ERC721/SenatePositions.sol#L488)

contracts/ERC721/SenatePositions.sol#L478-L494


 - [ ] ID-2
[SenatePositions.isConsul(address)](contracts/ERC721/SenatePositions.sol#L407-L425) uses timestamp for comparisons
	Dangerous comparisons:
	- [activeConsuls[i] == _address && block.timestamp < consuls[ownedTokenId].endTime](contracts/ERC721/SenatePositions.sol#L419)

contracts/ERC721/SenatePositions.sol#L407-L425


 - [ ] ID-3
[SenatePositions.isSenator(address)](contracts/ERC721/SenatePositions.sol#L432-L448) uses timestamp for comparisons
	Dangerous comparisons:
	- [activeSenators[i] == _address && block.timestamp < senators[ownedTokenId].endTime](contracts/ERC721/SenatePositions.sol#L442)

contracts/ERC721/SenatePositions.sol#L432-L448


 - [ ] ID-4
[SenatePositions.isCaesar(address)](contracts/ERC721/SenatePositions.sol#L501-L517) uses timestamp for comparisons
	Dangerous comparisons:
	- [activeCaesar[i] == _address && block.timestamp < caesars[ownedTokenId].endTime](contracts/ERC721/SenatePositions.sol#L511)

contracts/ERC721/SenatePositions.sol#L501-L517


## costly-loop
Impact: Informational
Confidence: Medium
 - [ ] ID-5
[SenatePositions.burn(uint256)](contracts/ERC721/SenatePositions.sol#L234-L313) has costly operations inside a loop:
	- [activeSenators = temp_scope_5](contracts/ERC721/SenatePositions.sol#L287)

contracts/ERC721/SenatePositions.sol#L234-L313


 - [ ] ID-6
[SenatePositions.burn(uint256)](contracts/ERC721/SenatePositions.sol#L234-L313) has costly operations inside a loop:
	- [activeConsuls = temp](contracts/ERC721/SenatePositions.sol#L245)

contracts/ERC721/SenatePositions.sol#L234-L313


 - [ ] ID-7
[SenatePositions.burn(uint256)](contracts/ERC721/SenatePositions.sol#L234-L313) has costly operations inside a loop:
	- [activeCensors = temp_scope_1](contracts/ERC721/SenatePositions.sol#L259)

contracts/ERC721/SenatePositions.sol#L234-L313


 - [ ] ID-8
[SenatePositions.burn(uint256)](contracts/ERC721/SenatePositions.sol#L234-L313) has costly operations inside a loop:
	- [activeTribunes = temp_scope_3](contracts/ERC721/SenatePositions.sol#L273)

contracts/ERC721/SenatePositions.sol#L234-L313


 - [ ] ID-9
[SenatePositions.burn(uint256)](contracts/ERC721/SenatePositions.sol#L234-L313) has costly operations inside a loop:
	- [activeCaesar = temp_scope_7](contracts/ERC721/SenatePositions.sol#L301)

contracts/ERC721/SenatePositions.sol#L234-L313


## cyclomatic-complexity
Impact: Informational
Confidence: High
 - [ ] ID-10
[SenatePositions.burn(uint256)](contracts/ERC721/SenatePositions.sol#L234-L313) has a high cyclomatic complexity (16).

contracts/ERC721/SenatePositions.sol#L234-L313


## solc-version
Impact: Informational
Confidence: High
 - [ ] ID-11
solc-0.8.20 is not recommended for deployment

## naming-convention
Impact: Informational
Confidence: High
 - [ ] ID-12
Parameter [SenatePositions.isTribune(address)._address](contracts/ERC721/SenatePositions.sol#L478) is not in mixedCase

contracts/ERC721/SenatePositions.sol#L478


 - [ ] ID-13
Parameter [SenatePositions.isSenator(address)._address](contracts/ERC721/SenatePositions.sol#L432) is not in mixedCase

contracts/ERC721/SenatePositions.sol#L432


 - [ ] ID-14
Parameter [SenatePositions.updateTermLength(ISenatePositions.Position,uint256)._newTermLength](contracts/ERC721/SenatePositions.sol#L320) is not in mixedCase

contracts/ERC721/SenatePositions.sol#L320


 - [ ] ID-15
Parameter [SenatePositions.burn(uint256)._tokenId](contracts/ERC721/SenatePositions.sol#L234) is not in mixedCase

contracts/ERC721/SenatePositions.sol#L234


 - [ ] ID-16
Parameter [SenatePositions.updateSenateAddress(address)._updatedSenateAddress](contracts/ERC721/SenatePositions.sol#L350) is not in mixedCase

contracts/ERC721/SenatePositions.sol#L350


 - [ ] ID-17
Parameter [SenatePositions.getPosition(address)._address](contracts/ERC721/SenatePositions.sol#L386) is not in mixedCase

contracts/ERC721/SenatePositions.sol#L386


 - [ ] ID-18
Parameter [SenatePositions.updateTermLength(ISenatePositions.Position,uint256)._position](contracts/ERC721/SenatePositions.sol#L320) is not in mixedCase

contracts/ERC721/SenatePositions.sol#L320


 - [ ] ID-19
Parameter [SenatePositions.isConsul(address)._address](contracts/ERC721/SenatePositions.sol#L407) is not in mixedCase

contracts/ERC721/SenatePositions.sol#L407


 - [ ] ID-20
Parameter [SenatePositions.mint(ISenatePositions.Position,address)._position](contracts/ERC721/SenatePositions.sol#L178) is not in mixedCase

contracts/ERC721/SenatePositions.sol#L178


 - [ ] ID-21
Parameter [SenatePositions.mint(ISenatePositions.Position,address)._to](contracts/ERC721/SenatePositions.sol#L178) is not in mixedCase

contracts/ERC721/SenatePositions.sol#L178


 - [ ] ID-22
Parameter [SenatePositions.tokenURI(uint256)._tokenId](contracts/ERC721/SenatePositions.sol#L362) is not in mixedCase

contracts/ERC721/SenatePositions.sol#L362


 - [ ] ID-23
Parameter [SenatePositions.isCensor(address)._address](contracts/ERC721/SenatePositions.sol#L455) is not in mixedCase

contracts/ERC721/SenatePositions.sol#L455


 - [ ] ID-24
Parameter [SenatePositions.isCaesar(address)._address](contracts/ERC721/SenatePositions.sol#L501) is not in mixedCase

contracts/ERC721/SenatePositions.sol#L501


## similar-names
Impact: Informational
Confidence: Medium
 - [ ] ID-25
Variable [SenatePositions.burn(uint256).temp_scope_3](contracts/ERC721/SenatePositions.sol#L270) is too similar to [SenatePositions.burn(uint256).temp_scope_5](contracts/ERC721/SenatePositions.sol#L284)

contracts/ERC721/SenatePositions.sol#L270


 - [ ] ID-26
Variable [SenatePositions.burn(uint256).temp_scope_1](contracts/ERC721/SenatePositions.sol#L256) is too similar to [SenatePositions.burn(uint256).temp_scope_3](contracts/ERC721/SenatePositions.sol#L270)

contracts/ERC721/SenatePositions.sol#L256


 - [ ] ID-27
Variable [SenatePositions.burn(uint256).temp_scope_1](contracts/ERC721/SenatePositions.sol#L256) is too similar to [SenatePositions.burn(uint256).temp_scope_7](contracts/ERC721/SenatePositions.sol#L298)

contracts/ERC721/SenatePositions.sol#L256


 - [ ] ID-28
Variable [SenatePositions.burn(uint256).temp_scope_5](contracts/ERC721/SenatePositions.sol#L284) is too similar to [SenatePositions.burn(uint256).temp_scope_7](contracts/ERC721/SenatePositions.sol#L298)

contracts/ERC721/SenatePositions.sol#L284


 - [ ] ID-29
Variable [SenatePositions.burn(uint256).temp_scope_1](contracts/ERC721/SenatePositions.sol#L256) is too similar to [SenatePositions.burn(uint256).temp_scope_5](contracts/ERC721/SenatePositions.sol#L284)

contracts/ERC721/SenatePositions.sol#L256


 - [ ] ID-30
Variable [SenatePositions.burn(uint256).temp_scope_3](contracts/ERC721/SenatePositions.sol#L270) is too similar to [SenatePositions.burn(uint256).temp_scope_7](contracts/ERC721/SenatePositions.sol#L298)

contracts/ERC721/SenatePositions.sol#L270


## immutable-states
Impact: Optimization
Confidence: High
 - [ ] ID-31
[SenatePositions.timelockContract](contracts/ERC721/SenatePositions.sol#L100) should be immutable 

contracts/ERC721/SenatePositions.sol#L100


