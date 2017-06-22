% CDI environment indicator - tropical timber data extraction and analysis

clc
clear all

% % specify analysis folder
%
% cd 'C:\Users\Hauke\Desktop\CDI trade analysis\GTAP_full_database';

%% 1. Data import

% Import comtrade excel file that hosts the comtrade country codes WHICH
% ARE EVER SO SLIGHTLY DIFFERENT FROM ISO CODES:
% http://unstats.un.org/unsd/tradekb/Attachment321.aspx?AttachmentType=1
% Import data from spreadsheet

[~, ~, CDI.original_comtrade_codes] = xlsread('Country Code and Name ISO2 ISO3.xls','Sheet1','A2:I289');
CDI.original_comtrade_codes(cellfun(@(x) ~isempty(x) && isnumeric(x) && isnan(x),CDI.original_comtrade_codes)) = {''};

%% import file with Regions

[~, ~, env_country_names] = xlsread('Environment component 2017.xlsx','2016','A228:B255');
env_country_names(cellfun(@(x) ~isempty(x) && isnumeric(x) && isnan(x),env_country_names)) = {''};

% rename 'South Korea' (as called in Excel) to 'Korea Republic of'
CDI.env_country_names = env_country_names;

CDI.env_country_names{strmatch('South Korea',CDI.env_country_names(:,1)),1} = 'Rep. of Korea';

CDI.env_country_names{strmatch('Czech Republic',CDI.env_country_names(:,1)),1} = 'Czech Rep.';

CDI.env_country_names{strmatch('United States',CDI.env_country_names(:,1)),1} = 'USA';


%% CDI country_codes

for i=1:length(CDI.env_country_names)
    try
        CDI.countries_codes.comtrade(i,:) = [CDI.original_comtrade_codes(strmatch(CDI.env_country_names(i),CDI.original_comtrade_codes(:,2),'exact'),1)];
    catch
        
        % 'Europe' gets country 97 for EU 28
        
        CDI.countries_codes.comtrade{28,:} = [97];
    end
end

% Column 2 assigns the country codes to each CDI country but with 97 written into every EU country PLUS NORWAY AND SWITZERLAND

CDI.countries_codes.comtrade(:,2) = CDI.countries_codes.comtrade(:,1);

for i=1:length(CDI.env_country_names)
    % If EU 28 country or Norway or Switzerland, because it has the average timber import value for Europe in 2016, assign EU-28
    if CDI.env_country_names{i,2} == CDI.env_country_names{2,2}
        CDI.countries_codes.comtrade{i,2} = 97;
    end
end

% Same as column above but with the country codes for Norway and
% Switzerland put back in
CDI.countries_codes.comtrade(:,3) = CDI.countries_codes.comtrade(:,2);

% Norway row
CDI.countries_codes.comtrade(strmatch('Norway',CDI.env_country_names(:,1)),3) = CDI.countries_codes.comtrade(strmatch('Norway',CDI.env_country_names(:,1)),1);

% Switzerland row
CDI.countries_codes.comtrade(strmatch('Switzerland',CDI.env_country_names(:,1)),3) = CDI.countries_codes.comtrade(strmatch('Switzerland',CDI.env_country_names(:,1)),1);

% Unique country codes of CDI countries for Comtrade call: EU-28, Norway
% and Switzerland plus all the rest (US, Newzealand, etc.)

unique_comtrade = unique([CDI.countries_codes.comtrade{:,1}]);

% print them so that they are Comma seperated for pasting in the Comtrade
% webinterface here: https://comtrade.un.org/db/dqQuickQuery.aspx

csvwrite('unique_comtrade.dat',unique_comtrade);
type unique_comtrade.dat;
% World country code is: 0 and should be added; 97 for EU should be taken
% out

'World country code is: 0 and should be added; 97 for EU should be taken out'
world = 0

%% import comtrade data using the script found in import_comtrade.m - data comes from 2015

new_import_comtrade;

% Variable name is: comtradetimberimports;

% find world imports of timber for all CDI countries

for i=1:[length(CDI.countries_codes.comtrade)-1]
    
    CDI.timber_imports.world.rows(i,:) = find(comtradetimberimports(:,2) == CDI.countries_codes.comtrade{i,1} & comtradetimberimports(:,4) == world);
    
end

for i=1:[length(CDI.countries_codes.comtrade)-1]
    CDI.world_timber.country_code{i,:} = CDI.countries_codes.comtrade{i,1};
    CDI.timber_imports.world.imports{i,:} = sum(comtradetimberimports(CDI.timber_imports.world.rows(i,1:2),10));
end

% sum European CDI countries World timber imports and
% write them in CDI.timber_imports.world.imports_EU_NRW_SWZ_combined

CDI.timber_imports.world.imports_EU_NRW_SWZ_combined = CDI.timber_imports.world.imports;

european_countries = find([CDI.countries_codes.comtrade{:,2}] == 97);
% all but not the 'Europe'

for i=1:length(CDI.countries_codes.comtrade)
    % if CDI country is part of EU 28 or NRW or SWZ
    
    if CDI.countries_codes.comtrade{i,2} == 97
        
        CDI.timber_imports.world.imports_EU_NRW_SWZ_combined{i,:} = sum([CDI.timber_imports.world.imports{european_countries(1:end-1)}]);
        
    end
end

% find all rows of imports for each country from other CDI countries

for i=1:length(CDI.countries_codes.comtrade)
    
    CDI.timber_imports.CDIcountries.rows{i,:} = find(comtradetimberimports(:,2) == CDI.countries_codes.comtrade{i,1} & ismember(comtradetimberimports(:,4),unique_comtrade'));
    
end

% % write CDI country imports for every CDI country into

for i=1:length(CDI.countries_codes.comtrade)
    
    CDI.timber_imports.CDIcountries.imports{i,:} = comtradetimberimports(CDI.timber_imports.CDIcountries.rows{i,1}(:,1),10); %
    
end

% add all European World timber imports together and write them in CDI.timber_imports.CDIcountries.imports_EU_NRW_SWZ_combined

for i=1:length(CDI.countries_codes.comtrade)
    % if CDI country is part of EU 28 or NRW or SWZ
    
    if CDI.countries_codes.comtrade{i,2} == 97
        
        CDI.timber_imports.sum_of_CDIcountries.imports = 0;
        
        for g=[european_countries(1:end-1)]
            CDI.timber_imports.sum_of_CDIcountries.imports = CDI.timber_imports.sum_of_CDIcountries.imports + sum(CDI.timber_imports.CDIcountries.imports{g})
        end
        
        CDI.timber_imports.CDIcountries.imports_EU_NRW_SWZ_combined{i,:} = CDI.timber_imports.sum_of_CDIcountries.imports;
        
    else
        CDI.timber_imports.CDIcountries.imports_EU_NRW_SWZ_combined{i,:} = sum(CDI.timber_imports.CDIcountries.imports{i,:});
        
    end
end

for i=1:length(CDI.countries_codes.comtrade)
    
    CDI.timber_imports.CDIcountries.imports_EU_not_combined{i,:} = sum(CDI.timber_imports.CDIcountries.imports{i,:});
    
end
% substract the imports from other CDI countries from World Imports of
% timber

for i=1:length(CDI.countries_codes.comtrade)
    
    CDI.timber_imports.world_minus_combined_CDI{i,:} = [CDI.timber_imports.world.imports_EU_NRW_SWZ_combined{i,1} - CDI.timber_imports.CDIcountries.imports_EU_NRW_SWZ_combined{i,1}];
end

% extract census data from 2015 from https://www.census.gov/population/international/data/idb/rank.php

census_import

CDI.env_country_names{strmatch('Rep. of Korea',CDI.env_country_names(:,1)),1} = 'Korea, South';

CDI.env_country_names{strmatch('Czech Rep.',CDI.env_country_names(:,1)),1} = 'Czechia';

CDI.env_country_names{strmatch('USA',CDI.env_country_names(:,1)),1} = 'United States';

for i=1:[length(CDI.countries_codes.comtrade)-1]
    CDI.env_country_names{i,3} = census1(strmatch(CDI.env_country_names(i,1),census1(:,1)),2)
    CDI.population(i,1) = census1(strmatch(CDI.env_country_names(i,1),census1(:,1)),2)
end

% add all European World countries populations together and write them in
% CDI.population(i,2)

CDI.population(:,2) = CDI.population(:,1);

for i=1:length(CDI.countries_codes.comtrade)
    % if CDI country is part of EU 28 or NRW or SWZ
    
    if CDI.countries_codes.comtrade{i,2} == 97
        
     CDI.population(i,2) = {sum([CDI.population{european_countries(1:end-1)}])}
        
    end
end

% Final output file


output_file(:,1) = CDI.timber_imports.world_minus_combined_CDI;

output_file(:,2) = CDI.population(:,2);

xlswrite('CDI_timber_output',output_file);