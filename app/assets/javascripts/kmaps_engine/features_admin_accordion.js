  $(document).ready(function() {

    if( $('.logged-in #featureShow #accordion').length ) { // only run this on the admin feature accordion

      const section = window.location.href.split('=')[1];

      switch(section) {
     
        case('captions'):
          handleFeatureAccordion('collapseFour');
          break;
        case('collections'):
          handleFeatureAccordion('collapseTwo');
          break;
        case('definitions'):
          handleFeatureAccordion('collapseTen');
          break;
        case('descriptions'):
          handleFeatureAccordion('#collapseNine');
          break;
        case('etymologies'):
          handleFeatureAccordion('collapseThirteen');
          break;
        case('geocodes'):
          handleFeatureAccordion('collapseSeven');
          break;
        case('illustrations'):
          handleFeatureAccordion('collapseSix');
          break;
        case('names'):
          handleFeatureAccordion('collapseThree');
          break;
        case('passages'):
          handleFeatureAccordion('collapsePassages');
          break;
        case('recordings'):
          handleFeatureAccordion('collapseEleven');
          break;
        case('relations'):
          handleFeatureAccordion('collapseEight');
          break;
        case('subjectAssociations'):
          handleFeatureAccordion('collapseTwelve');
          break;
        case('summaries'):
          handleFeatureAccordion('collapseFive');
          break;
        default:
          console.log("default");
          break;
      }
    
      function handleFeatureAccordion(el){
        // General Information is shown by default so hide it
        $('#collapseOne').collapse('hide');
        $('#' + el).collapse('toggle');
        setTimeout(1000);
        //TODO there is something else running on the page that prevents this from working consistently.
        //It has to do with the sidebar list of terms.
        document.getElementById(el).scrollIntoView({behavior: "smooth" });
      }
    }
});


